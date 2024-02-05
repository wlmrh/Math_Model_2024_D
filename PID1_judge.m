% situation(month)返回非水坝因素对于水容量的平均变化(m^3/month)
% 需要保存在工作区的数据：当前状态与目标状态之间水量的差距
clear; clc;
set1 = [22.31926 6.90434  6.7692 553.8045];
set2 = [115.83953 4.81541 5.94392 -917.35772];
set3 = [6474.46584 -11537.51703 8218.87738 -2690.42741 464.32447 -44.01315 2.1742 -0.04382];
Month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
kp = 2; ki = 3; kd = -0.1; pid_weight = 1;
ideal_level = 183.8182; %  理想水位(m)
lake_area =  82103000000; % 当前湖的表面积(m^2)
data = xlsread('Problem_D_Great_Lakes.xlsx',"Lake Superior", "B8:M30");
datas = (data');
lake_depth = (datas(:))';% 当前湖在各个月份的深度
ideal = lake_area * ideal_level / 3; % 当前湖的最佳水量（自动计算）
cases = lake_area * lake_depth / 3; % 当前湖的水量
srt = 204; limt = 47909723789;
%计算从2000年开始每一个月的水量变化
new_data1 = xlsread('2021PrecipCoordination.xlsx', "2021Coordination(mm)", "B113:M132");
final_data = new_data1 * lake_area / 1000;
new_data1 = xlsread('evaporation_sup.csv', "B55:M74");
final_data = final_data - new_data1 * lake_area / 1000;
new_data2 = xlsread('runoff_sup_arm.csv', "D1108:D1347"); new_data2 = new_data2 * 3600 * 24 * 30;
for i = 1 : 20
    for j = 1 : 12
        final_data(i, j) = final_data(i, j) - new_data2((i - 1) * 12 + j);
    end
end
final_datas = final_data';
real = (final_datas(:))';   
%
Mary_avg = xlsread('Problem_D_Great_Lakes.xlsx',"St. Mary's River", "B31:M31");
err(srt) = cases(204) - ideal; rst(srt) = cases(srt); integration(srt) = 0; interval = 1; time(srt) = 0;
other(srt) = situation(set1, set2, set3, rem(srt,12), lake_area) * lake_area / 1000; % situation(month)返回非水坝因素对于水容量的平均变化(m^3/month)
pid(srt) = real(srt) / pid_weight;
sum_of_error = 0;
if pid(srt) > limt
    pid(srt) = limt
elseif pid(srt) < (-limt)
    pid(srt) = (-limt)
end
for i =  srt + 1 : 1 : srt + 12
    time(i) = i;
    other(i) = situation(set1, set2, set3, rem(i, 12), lake_area) * lake_area / 1000; % 其他因素对于水流量的影响：降水，蒸发，用水
    rst(i) = rst(i - 1) + other(i - 1) - pid_weight * pid(i - 1); % 根据上个一月的水量，上一月的开水坝情况和上一个月其他因素的影响计算得出该月的水量
    err(i) = rst(i) - ideal; % 计算当前值与目标值之间的水流量,参数为上个月的实际通过水流量和其他因素other的函数
    integration(i) = integration(i - 1) + (err(i) + err(i - 1)) / 2 * interval;
    dif(i) = (err(i) - err(i - 1)) / interval; 
    pid(i) = kp * err(i) + (i / length(lake_depth)) * ki * integration(i) + kd * dif(i) + other(i) / pid_weight;
    if pid(i) > limt
        pid(i) = limt
    elseif pid(i) < (-limt)
        pid(i) = (-limt)
    end
    index = rem(i - 1, 12) + 1; year = 2000 + fix((i - 1) / 12);
    final_date = [num2str(year), '年', num2str(index), '月'];
    if pid(i) > Mary_avg(index) * 3600 * 24 * 30  %%
        out(i) = Mary_avg(index) * 3600 * 24 * 30;
        disp([final_date, "整月开闸", "水库存储水量为：", num2str(pid(i) - Mary_avg(index) * 3600 * 24 * 30), "m ^ 3"]);
    elseif pid(i) < 0
        out(i) = 0;
        disp([final_date, "水坝放水:", num2str(-pid(i)), "m ^ 3"]);
    else
        out(i) = pid(i);
        open_period = pid(i) / Mary_avg(index);
        disp([final_date, "水坝开放时间为:", num2str(open_period), 's']);
    end
    show(i) = err(i) / ideal;
end
show(1) = err(1) / ideal;
plot(time, show);
xlim([srt + 1 srt + 12]);
yticks([-0.0025 -0.0020 -0.0015 -0.001 -0.0005 0 0.0005 0.001 0.0015 0.002 0.0025]);
set(gca,'XTickLabel',{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'});
set(gca,'yticklabel',{'-0.25%', '-0.2%', '-0.15%', '-0.1%', '-0.05%', '0', '0.05%', '0.1%', '0.15%', '0.2%', '0.25%'});
xlabel('Month') 
ylabel('Average month error rate')
title("2017 Lake Superior");