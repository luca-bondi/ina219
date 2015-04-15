clc;
clear;
%% Arduino INA219 data plot

%% Parameters

% Arduino serial port device
logFile = 'screenlog.0';

% Timestamp interval
ts = [50000 60000];

%% Read data
fileP = fopen(logFile,'r');
readGood = true;
timeVector = [];
busVVector = [];
shuntVVector = [];
loadVVector = [];
currentVector = [];
while readGood && ~feof(fileP)
    row = fgets(fileP);
    try
        readData = sscanf(row,'%d,%f,%f,%f,%f\n');
        
        time = readData(1);
        
        if time > ts(2)
            readGood = false;
            break;
        end
          
        if time >= ts(1)
            busV = readData(2);
            shuntV = readData(3);
            loadV = readData(4);
            current = readData(5);
        
            timeVector = [timeVector ; time];
            busVVector = [busVVector ; busV];
            shuntVVector = [shuntVVector ; shuntV];
            loadVVector = [loadVVector ; loadV];
            currentVector = [currentVector ; current];
        end
    catch exception
        %disp(exception);
    end
end

fclose(fileP);

timeVector = timeVector / 1000;
busPowerVector = busVVector .* currentVector ./ 1000;
loadPowerVector = loadVVector .* currentVector ./ 1000;

%% Draw plots
xlimVal = [min(timeVector),max(timeVector)];

fig = figure(1);
subplot(2,3,1);
busVPlot = plot(timeVector,busVVector);
busVPlot.XDataSource = 'timeVector';
busVPlot.YDataSource = 'busVVector';
ylabel('Bus Voltage [V]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 6]);

subplot(2,3,2);
shuntVPlot = plot(timeVector,shuntVVector);
shuntVPlot.XDataSource = 'timeVector';
shuntVPlot.YDataSource = 'shuntVVector';
ylabel('Shunt Voltage [mV]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 100]);

subplot(2,3,3);
loadVPlot = plot(timeVector,loadVVector);
loadVPlot.XDataSource = 'timeVector';
loadVPlot.YDataSource = 'loadVVector';
ylabel('Load Voltage [V]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 5.5]);

subplot(2,3,4);
currentPlot = plot(timeVector,currentVector);
currentPlot.XDataSource = 'timeVector';
currentPlot.YDataSource = 'currentVector';
ylabel('Current Drain [mA]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 1000]);

subplot(2,3,5);
busPowerplot = plot(timeVector,busPowerVector);
busPowerplot.XDataSource = 'timeVector';
busPowerplot.YDataSource = 'busPowerVector';
ylabel('Bus Power [W]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 5]);

subplot(2,3,6);
loadPowerPlot = plot(timeVector,loadPowerVector);
loadPowerPlot.XDataSource = 'timeVector';
loadPowerPlot.YDataSource = 'loadPowerVector';
ylabel('Load Power [W]');
xlabel('Time [s]');
xlim(xlimVal);
ylim([0 5]);
