clear;

%% Parameters
%Desired Duty Cycle
desired_dc = 30;

%% Load Data
[deb_ts,deb_power]=csv_ts_power('CTA vs ATC Telos.csv');
[ti_ts,ti_power]=csv_ts_power('BBB-TI-cam,telos-sleep.csv');

%% Select indexes
deb_idxs = find(deb_ts > 63330 & deb_ts < 67350);
ti_idxs = find(ti_ts > 30600 & ti_ts < 91380);

deb_ts = deb_ts(deb_idxs);
deb_power = deb_power(deb_idxs);

ti_ts = ti_ts(ti_idxs);
ti_power = ti_power(ti_idxs);

%% Fix timings offsets
deb_ts_os = -deb_ts(1);
ti_ts_os = deb_ts(end)+deb_ts_os-ti_ts(1)+1;

deb_ts  = deb_ts + deb_ts_os; 
ti_ts  = ti_ts + ti_ts_os;

%% Duty cycle
ti_sleep_idxs = find(ti_power < 0.25);
ti_sleep_1s_idxs = find(ti_ts < (ti_ts(ti_sleep_idxs(1)) + 1000) & ti_ts > ti_ts(ti_sleep_idxs(1)));
ti_sleep_1s_power = ti_power(ti_sleep_1s_idxs);
ti_sleep_1s_ts = ti_ts(ti_sleep_1s_idxs);

min_dc = (ti_ts(end)-range(ti_ts(ti_sleep_idxs)))/1000;

sec_to_add = floor(desired_dc-min_dc);
ti_power_sleep = repmat(ti_sleep_1s_power,sec_to_add,1);
ti_ts_sleep = repmat(ti_sleep_1s_ts,sec_to_add,1);

for idx = 1:sec_to_add
    idxs = (idx-1)*length(ti_sleep_1s_ts)+1:(idx)*length(ti_sleep_1s_ts);
    ti_ts_sleep(idxs) = ti_ts_sleep(idxs) + (idx-1)*1000;
end

ti_ts = [ti_ts(1:ti_sleep_idxs(1)-1) ; ti_ts_sleep; ti_ts(ti_sleep_idxs(end):end)-range(ti_ts(ti_sleep_idxs))+sec_to_add*1000];
ti_power = [ti_power(1:ti_sleep_idxs(1)-1) ; ti_power_sleep ; ti_power(ti_sleep_idxs(end):end)];

%% Different loads fixes
ti_power_fix_idxs = ti_ts < ti_ts(ti_sleep_idxs(1));
ti_power(ti_power_fix_idxs) = ti_power(ti_power_fix_idxs) + (1.928-1.500);

%% Save unified data
ts = [deb_ts ; ti_ts];
power = [deb_power ; ti_power];
save('ATC_Telos','ts','power');

%% Show plot
figure();
plot((deb_ts)/1000,deb_power,...
     (ti_ts)/1000,ti_power);
xlim([0 (ti_ts(end))/1000]);
ylabel('Power [W]');
xlabel('Time [s]');
title('ATC');

%% Energy
delta_ts = ts(2:end)-ts(1:end-1);
energy = sum(power(1:end-1).*delta_ts)/1000;
fprintf(1,'Cycle energy: %.2f J\n',energy);

delta_ts_ti = ti_ts(2:end)-ti_ts(1:end-1);
energy_ti = sum(ti_power(1:end-1).*delta_ts_ti)/1000;
fprintf(1,'Sleep energy: %.2f J\n',energy_ti);

delta_ts_deb = deb_ts(2:end)-deb_ts(1:end-1);
energy_deb = sum(deb_power(1:end-1).*delta_ts_deb)/1000;
fprintf(1,'Work energy: %.2f J\n',energy_deb);