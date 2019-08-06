clear
clc
close all

t0 = 0;
tf = 10;
initial_constrains_x = [0 0 0];
final_contrains_x = [5 0 0];
initial_constrains_y = [0 0 0];
final_contrains_y = [3 0 0];
initial_constrains_z = [-1.5 0 0];
final_contrains_z = [-2.5 0 0];
initial_constrains_psi = [0 0 0];
final_contrains_psi = [0 0 0];

[c_p_x,c_v_x,c_a_x,c_j_x] = generate_polynomial_trajectory(initial_constrains_x,final_contrains_x,t0,tf);
[c_p_y,c_v_y,c_a_y,c_j_y] = generate_polynomial_trajectory(initial_constrains_y,final_contrains_y,t0,tf);
[c_p_z,c_v_z,c_a_z,c_j_z] = generate_polynomial_trajectory(initial_constrains_z,final_contrains_z,t0,tf);
[c_p_psi,c_v_psi,c_a_psi,~] = generate_polynomial_trajectory(initial_constrains_psi,final_contrains_psi,t0,tf);

time_step = 1/500;
states = zeros((tf-t0)/time_step,9);
x_ref = zeros((tf-t0)/time_step,1);
y_ref = zeros((tf-t0)/time_step,1);
z_ref = zeros((tf-t0)/time_step,1);
v_x_ref = zeros((tf-t0)/time_step,1);
v_y_ref = zeros((tf-t0)/time_step,1);
v_z_ref = zeros((tf-t0)/time_step,1);
a_x_ref = zeros((tf-t0)/time_step,1);
a_y_ref = zeros((tf-t0)/time_step,1);
a_z_ref = zeros((tf-t0)/time_step,1);
psi_ref = zeros((tf-t0)/time_step,1);
t = zeros((tf-t0)/time_step,1);
states(1,:) = [initial_constrains_x(1)-1 initial_constrains_y(1)+1 initial_constrains_z(1)...
    initial_constrains_x(2) initial_constrains_y(2) initial_constrains_z(2) 0 0 0];


for i = 1:(tf-t0)/time_step-1
    if i == 1
        t(i) = t0 + i * time_step;
        x_ref(i) = polyval(c_p_x,t(i));
        y_ref(i) = polyval(c_p_y,t(i));
        z_ref(i) = polyval(c_p_z,t(i));
        psi_ref(i) = polyval(c_p_psi,t(i));
        v_x_ref(i) = polyval(c_v_x,t(i));
        v_y_ref(i) = polyval(c_v_y,t(i));
        v_z_ref(i) = polyval(c_v_z,t(i));
        a_x_ref(i) = polyval(c_a_x,t(i));
        a_y_ref(i) = polyval(c_a_y,t(i));
        a_z_ref(i) = polyval(c_a_z,t(i));
    end
    [angular_rate_ff,T_ff] = feed_forward_controller(c_v_x,c_v_y,c_v_z,...
                                                 c_a_x,c_a_y,c_a_z,...   
                                                 c_j_x,c_j_y,c_j_z,...
                                                 c_p_psi,c_v_psi,t(i));
%     [angular_rate_fb,T_fb] = feed_back_controller([x_ref(i) y_ref(i) z_ref(i)],...
%                                                                psi_ref(i),states(i,:),T_ff);
% [angular_rate_fb,T_fb] = feed_back_controller_pid([x_ref(i) y_ref(i) z_ref(i)],...
%     psi_ref(i),states(i,:),T_ff);

    [angular_rate_fb,T] = feedback_controller_2([x_ref(i) y_ref(i) z_ref(i)]',...
                                [v_x_ref(i) v_y_ref(i) v_z_ref(i)]',...
                                [a_x_ref(i) a_y_ref(i) a_z_ref(i)]',...
                                states(i,:));
                            
    angular_rate = angular_rate_ff + angular_rate_fb;
    %T = T_ff; % + T_fb;
    states(i+1,:) =  states(i,:) + time_step * drone_model(states(i,:),[angular_rate' T])';
    
    t(i+1) = t0 + (i+1) * time_step;
    x_ref(i+1) = polyval(c_p_x,t(i+1));
    y_ref(i+1) = polyval(c_p_y,t(i+1));
    z_ref(i+1) = polyval(c_p_z,t(i+1));
    psi_ref(i+1) = polyval(c_p_psi,t(i+1));
    v_x_ref(i+1) = polyval(c_v_x,t(i+1));
    v_y_ref(i+1) = polyval(c_v_y,t(i+1));
    v_z_ref(i+1) = polyval(c_v_z,t(i+1));
    a_x_ref(i+1) = polyval(c_a_x,t(i+1));
    a_y_ref(i+1) = polyval(c_a_y,t(i+1));
    a_z_ref(i+1) = polyval(c_a_z,t(i+1));
end


figure(1)
subplot(3,1,1)
hold on
grid on
plot(t,x_ref);
plot(t,states(:,1));
legend('ref','real')
ylabel('x[m]')
subplot(3,1,2)
hold on
grid on
plot(t,y_ref);
plot(t,states(:,2));
ylabel('y[m]')
subplot(3,1,3)
hold on
grid on
plot(t,z_ref);
plot(t,states(:,3));
ylabel('z[m]')
xlabel('time[s]')
temp = 1;