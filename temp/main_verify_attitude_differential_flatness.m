clear
clc
close all

g = 9.8;
dx = -0.5;
dy = -0.5;
dz = -0.5;
z_w = [0 0 1]';

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

[cx,c_v_x,c_a_x] = generate_polynomial_trajectory(initial_constrains_x,final_contrains_x,t0,tf);
[cy,c_v_y,c_a_y] = generate_polynomial_trajectory(initial_constrains_y,final_contrains_y,t0,tf);
[cz,c_v_z,c_a_z] = generate_polynomial_trajectory(initial_constrains_z,final_contrains_z,t0,tf);
[cPsi,c_v_psi,c_a_psi] = generate_polynomial_trajectory(initial_constrains_psi,final_contrains_psi,t0,tf);

time_step = 1/500;
states = zeros((tf-t0)/time_step,6);
x_ref = zeros((tf-t0)/time_step,1);
y_ref = zeros((tf-t0)/time_step,1);
z_ref = zeros((tf-t0)/time_step,1);
psi_ref = zeros((tf-t0)/time_step,1);
t = zeros((tf-t0)/time_step,1);
states(1,:) = [initial_constrains_x(1) initial_constrains_y(1) initial_constrains_z(1)...
    initial_constrains_x(2) initial_constrains_y(2) initial_constrains_z(2)];


for i = 1:(tf-t0)/time_step-1
    if i == 1
        t(i) = t0 + i * time_step;
        x_ref(i) = polyval(cx,t(i));
        y_ref(i) = polyval(cy,t(i));
        z_ref(i) = polyval(cz,t(i));
    end
    
    v = [polyval(c_v_x,t(i)),polyval(c_v_y,t(i)),polyval(c_v_z,t(i))]';
    a = [polyval(c_a_x,t(i)),polyval(c_a_y,t(i)),polyval(c_a_z,t(i))]';
    psi = polyval(cPsi,t(i));
    
    x_c = [cos(psi) sin(psi) 0]';
    y_c = [-sin(psi) cos(psi) 0]';
    alpha = a - g*z_w-dx*v;
    beta = a - g*z_w-dy*v;
    
    x_b = cross(y_c,alpha)/norm(cross(y_c,alpha));
    y_b = cross(beta,x_b)/norm(cross(beta,x_b));
    z_b = cross(y_b,x_b);
    R = [x_b y_b z_b];
    R = R';
%     eul = rotm2eul(R);
%     phi = eul(3);
%     theta = eul(2);
%     psi = eul(1);
    T = z_b' * (a-g*z_w-dz*v);
    states(i+1,:) =  states(i,:) + time_step * drone_model_attitude(states(i,:),[phi theta psi T])';
    t(i+1) = t0 + (i+1) * time_step;
    x_ref(i+1) = polyval(cx,t(i+1));
    y_ref(i+1) = polyval(cy,t(i+1));
    z_ref(i+1) = polyval(cz,t(i+1));
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