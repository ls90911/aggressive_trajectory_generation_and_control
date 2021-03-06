function [c_p_x,c_v_x,c_a_x,c_j_x,c_p_y,c_v_y,c_a_y,c_j_y,...
    c_p_z,c_v_z,c_a_z,c_j_z,c_p_psi,c_v_psi,c_a_psi,tf] = ...
    generate_minimum_snap_trajectories(initial_constrains_x,final_contrains_x,...
    initial_constrains_y,final_contrains_y,...
    initial_constrains_z,final_contrains_z,...
    initial_constrains_psi,final_contrains_psi)

N = 7;
time_step = 0.01;
feasible = 1;
t0 = 0;
tf = 20;

p = 1;
while(feasible)
    [c_p_x,c_v_x,c_a_x,c_j_x] = generate_optimal_trajectory(N,t0,tf,initial_constrains_x,final_contrains_x);
    [c_p_y,c_v_y,c_a_y,c_j_y] = generate_optimal_trajectory(N,t0,tf,initial_constrains_y,final_contrains_y);
    [c_p_z,c_v_z,c_a_z,c_j_z] = generate_optimal_trajectory(N,t0,tf,initial_constrains_z,final_contrains_z);
    [c_p_psi,c_v_psi,c_a_psi,c_j_psi] = generate_optimal_trajectory(N,t0,tf,initial_constrains_psi,final_contrains_psi);
 
    inputs = zeros(round(tf/time_step),4);
    thrust = zeros(round(tf/time_step),2);
    t = zeros(round(tf/time_step),1);
    for i = 1:size(inputs,1)
        t(i) = i * time_step;
        inputs(i,:) = calculate_states(c_v_x,c_v_y,c_v_z,...
                                                 c_a_x,c_a_y,c_a_z,...   
                                                 c_j_x,c_j_y,c_j_z,...
                                                 c_p_psi,c_v_psi,t(i));
        if i ~= 1
            drate =  (inputs(i,:) -  inputs(i-1,:))/time_step;
            thrust(i-1,:) = calculate_force(drate,inputs(i-1,4));
            [flag_feasible] = check_feasible(thrust(i-1,:));
            feasible = feasible & flag_feasible;
        end
    end
    p = p+1;
    tf = tf - 0.1;
end

% figure(200)
% hold on
% plot(t,thrust(:,1))
% plot(t,thrust(:,2))
end

function F = calculate_force(drate,T)
    I = 0.001242;
    L = 0.08;
    m = 0.389;
    A = [1 1;1 -1];
    b = [abs(T)*m;I*drate(2)/L];
    F = linsolve(A,b)';
end

function [flag_feasible] = check_feasible(F)
    if max(F) > 2.1 || min(F) < 1.76
        flag_feasible = 0;
    else
        flag_feasible = 1;
    end
end