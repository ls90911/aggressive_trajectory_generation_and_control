clear
clc
close all

clear
clc
close all
dbstop if error
global ref states t inputs kp states_nn inputs_nn

kp = 20;

addpath("/usr/local/lib/");
addpath("/usr/local/include/esa_nn");
if not(libisloaded('libesa_nn'))
    loadlibrary('libesa_nn','esa_simulation.h','addheader','nn.h','addheader','nn_params.h','addheader','pd_gains.h')
end

libfunctions('libesa_nn','-full')

t0 = 0;

x_target = [1:0.5:10];
z_target = [0:-0.5:-5];
faster_rate = zeros(length(x_target),length(z_target));
thresh = 0.1;


for m = 1:length(x_target)
    for n = 1:length(z_target)
        initial_constrains_x = [0 0 0 0];
        final_contrains_x = [x_target(m) 0 0 0];
        initial_constrains_y = [0 0 0 0];
        final_contrains_y = [0 0 0 0];
        initial_constrains_z = [-2.5 0 0 0];
        final_contrains_z = [z_target(n) 0 0 0];
        initial_constrains_psi = [0 0 0 0];
        final_contrains_psi = [0 0 0 0];
        
        time_snap = 0;
        flag_snap = 1;
        time_nn = 0;
        flag_nn = 1;
        
        [c_p_x,c_v_x,c_a_x,c_j_x,c_p_y,c_v_y,c_a_y,c_j_y,...
            c_p_z,c_v_z,c_a_z,c_j_z,c_p_psi,c_v_psi,c_a_psi,tf] = ...
            generate_minimum_snap_trajectories(initial_constrains_x,final_contrains_x,...
            initial_constrains_y,final_contrains_y,...
            initial_constrains_z,final_contrains_z,...
            initial_constrains_psi,final_contrains_psi);
        
        
        time_step = 1/500;
        states = zeros(floor(tf-t0)/time_step,9);
        inputs = zeros(floor(tf-t0)/time_step,4);
        ref = zeros(floor(tf-t0)/time_step,10);
        t = zeros(floor(tf-t0)/time_step,1);
        states(1,:) = [initial_constrains_x(1) initial_constrains_y(1) initial_constrains_z(1)...
            initial_constrains_x(2) initial_constrains_y(2) initial_constrains_z(2) 0 0 0];
        
        states_nn = zeros(floor(tf-t0)/time_step,7);
        inputs_nn = zeros(floor(tf-t0)/time_step,2);
        states_nn(1,:) = [initial_constrains_x(1) initial_constrains_z(1) initial_constrains_x(2) initial_constrains_z(2) 0 0 0];
        
        for i = 1:(tf-t0)/time_step-1
            %% minimum snap
            if i == 1
                t(i) = t0 + i * time_step;
                ref(i,1) = polyval(c_p_x,t(i));
                ref(i,2) = polyval(c_p_y,t(i));
                ref(i,3) = polyval(c_p_z,t(i));
                ref(i,10) = polyval(c_p_psi,t(i));
                ref(i,4) = polyval(c_v_x,t(i));
                ref(i,5) = polyval(c_v_y,t(i));
                ref(i,6) = polyval(c_v_z,t(i));
                ref(i,7) = polyval(c_a_x,t(i));
                ref(i,8) = polyval(c_a_y,t(i));
                ref(i,9) = polyval(c_a_z,t(i));
            end
            
            [angular_rate_ff,T_ff] = feed_forward_controller(c_v_x,c_v_y,c_v_z,...
                c_a_x,c_a_y,c_a_z,...
                c_j_x,c_j_y,c_j_z,...
                c_p_psi,c_v_psi,t(i));
            
            [angular_rate_fb,T] = feedback_controller_2(ref(i,:),states(i,:));
            
            angular_rate = angular_rate_ff + angular_rate_fb;
            inputs(i,:) = [angular_rate' T];
            states(i+1,:) =  states(i,:) + time_step * drone_model(states(i,:),inputs(i,:))';
            if norm([states(i+1,1) states(i+1,3)] - [final_contrains_x(1) final_contrains_z(1)]) < thresh && flag_snap
                time_snap = t(i);
                flag_snap = 0;     
            end

            
            t(i+1) = t0 + (i+1) * time_step;
            ref(i+1,1) = polyval(c_p_x,t(i+1));
            ref(i+1,2) = polyval(c_p_y,t(i+1));
            ref(i+1,3) = polyval(c_p_z,t(i+1));
            ref(i+1,10) = polyval(c_p_psi,t(i+1));
            ref(i+1,4) = polyval(c_v_x,t(i+1));
            ref(i+1,5) = polyval(c_v_y,t(i+1));
            ref(i+1,6) = polyval(c_v_z,t(i+1));
            ref(i+1,7) = polyval(c_a_x,t(i+1));
            ref(i+1,8) = polyval(c_a_y,t(i+1));
            ref(i+1,9) = polyval(c_a_z,t(i+1));
            
            %% nn simulation
            if i ~= 1
                currentStates = [final_contrains_x(1)-states_nn(i-1,1), -states_nn(i-1,3),...
                    -states_nn(i-1,2)+final_contrains_z(1), -states_nn(i-1,4), -states_nn(i-1,5),...
                    -states_nn(i-1,6)];
                control_temp = [0 0];
                [~,control] = calllib('libesa_nn','nn',currentStates,control_temp);
                F_min = 1.76;
                F_max = 2.35;
                FL = F_min + control(1)*(F_max - F_min);
                FR = F_min + control(2)*(F_max - F_min);
                theta = states_nn(i-1,5);
                a_z_b_cmd = -(FL+FR)/0.389;
                I_xx = 0.001242;
                L = 0.08;
                dq_cmd = (FL-FR)/I_xx*L;
                inputs_nn(i,:) = [FL FR];
                states_nn(i,:) = states_nn(i-1,:) + time_step * drone_model_2d(states_nn(i-1,:),[a_z_b_cmd dq_cmd]);
                if norm([states_nn(i,1) states_nn(i,2)] - [final_contrains_x(1) final_contrains_z(1)]) < thresh && flag_nn
                    time_nn = t(i);
                    flag_nn = 0;
                end
            end   
        end
       faster_rate(m,n) = (time_snap-time_nn)/time_snap; 
    end
end


temp = 1;