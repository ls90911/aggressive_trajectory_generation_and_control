function [] = compare_minimum_snap_vs_nn(fig_num)
global states states_nn ref t inputs inputs_nn t_nn

dRate = diff(inputs)/0.002;
thrust = zeros(size(dRate,1),2);

I = 0.001242;
L = 0.08;
m = 0.389;
A = [1 1;1 -1];

for i = 1:size(thrust,1)
    b = [abs(inputs(i,4))*m;I*dRate(i,2)/L];
    thrust(i,:) = linsolve(A,b)';
end

figure(fig_num)
subplot(2,1,1)
hold on
grid on
%plot(t,ref(:,1));
plot(t(1:end-1),states(1:end-1,1),'k-');
plot(t_nn,states_nn(:,1),'k-.');
legend('OPT','OOC')
ylabel('x[m]')
subplot(2,1,2)
hold on
grid on
%plot(t,ref(:,3));
plot(t(1:end-1),states(1:end-1,3),'k-');
plot(t_nn,states_nn(:,2),'k-.');
ylabel('z[m]')
xlabel('time[s]')

thrust(1,:) = thrust(2,:);
inputs_nn(1,:) = inputs_nn(2,:);

figure(fig_num+1)
subplot(2,1,1)
hold on
grid on
plot(t(1:end-2),thrust(1:end-1,1),'k-');
plot(t_nn,inputs_nn(:,1),'k-.');
legend('OPT','OOC')
ylabel('F_1[N]')
subplot(2,1,2)
hold on
grid on
plot(t(1:end-2),thrust(1:end-1,2),'k-');
plot(t_nn,inputs_nn(:,2),'k-.');
ylabel('F_2[N]')
xlabel('time[s]')

end