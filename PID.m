% situation(month)返回非水坝因素对于水容量的平均变化(m^3/month)
% 需要保存在工作区的数据：当前状态与目标状态之间水量的差距
clear; clc;
set1 = [22.31926 6.90434  6.7692 553.8045];
set2 = [115.83953 4.81541 5.94392 -917.35772];
set3 = [6474.46584 -11537.51703 8218.87738 -2690.42741 464.32447 -44.01315 2.1742 -0.04382];
Month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
kp = 1.5; ki = 3; kd = 0.1; pid_weight = 1;
ideal_level = 183.3464; %  理想水位(m)
lake_area =  82103000000; % 当前湖的表面积(m^2)
data = xlsread('Problem_D_Great_Lakes.xlsx',"Lake Superior", "B8:M30");
datas = (data');    
lake_depth = (datas(:))';% 当前湖在各个月份的深度
ideal = lake_area * ideal_level / 3; % 当前湖的最佳水量（自动计算）
cases = lake_area * lake_depth / 3; % 当前湖的水量
Mary_avg = xlsread('Problem_D_Great_Lakes.xlsx',"St. Mary's River", "B31:M31");
err(1) = cases(1) - ideal; rst(1) = cases(1); integration(1) = 0; interval = 1; time(1) = 0;
other(1) = situation(set1, set2, set3, 1, lake_area) * lake_area / 1000; % situation(month)返回非水坝因素对于水容量的平均变化(m^3/month)
pid(1) = other(1) / pid_weight;
for i =  2 : 1 : length(lake_depth)
    time(i) = i;
    other(i) = situation(set1, set2, set3, rem(i, 12), lake_area) * lake_area / 1000; % 其他因素对于水流量的影响：降水，蒸发，用水
    rst(i) = rst(i - 1) + other(i - 1) - pid_weight * pid(i - 1); % 根据上个一月的水量，上一月的开水坝情况和上一个月其他因素的影响计算得出该月的水量
    err(i) = rst(i) - ideal; % 计算当前值与目标值之间的水流量,参数为上个月的实际通过水流量和其他因素other的函数
    integration(i) = integration(i - 1) + (err(i) + err(i - 1)) / 2 * interval;
    dif(i) = (err(i) - err(i - 1)) / interval; 
    pid(i) = kp * err(i) + ki * integration(i) + kd * dif(i) + other(i) / pid_weight;
    index = rem(i - 1, 12) + 1; year = 2000 + fix((i - 1) / 12);
    final_date = [num2str(year), '年', num2str(index), '月'];
    if pid(i) > Mary_avg(index) * 3600 * 24 * 30  %%
        disp([final_date, "整月开闸", "水库存储水量为：", num2str(pid(i) - Mary_avg(index) * 3600 * 24 * 30), "m ^ 3"]);
    elseif pid(i) < 0
        disp([final_date, "水坝放水:", num2str(-pid(i)), "m ^ 3"]);
    else
        open_period = pid(i) / Mary_avg(index);
        disp([final_date, "水坝开放时间为:", num2str(open_period), 's']);
    end
    show(i) = err(i) / ideal;
end
show(1) = err(1) / ideal;
plot(time, err);
xlim([0 28]);
xticks([0 2 4 6 8 10 12 14 16 18 20 22 24 26 28]);
%set(gca,'XTickLabel',{'2', '4', '6', '8', '10', '12', '14', '16', '18', '20', '22', '24'});
set(gca,'yticklabel',{'-0.8%', '-0.6%', '-0.4%', '-0.2%', '0', '0.2%', '0.4%', '0.6%', '0.8%'});
xlabel('Month') 
ylabel('Average month error rate')