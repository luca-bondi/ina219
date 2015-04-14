clc;
%% Arduino INA219 data plot and storage
%  Acquisition ends on figure close or maxPeriod reached

%% Parameters

% Acquisition period according to Arduino code
acquisitionPeriod = 500; %ms
% Interval shown in plots
plotPeriod = 30; %s
% Maximum recordable interval (to preallocate memory)
maxPeriod = 3600; %s
% Arduino serial port device
serialPortDevice = '/dev/tty.usbmodem1d11421';
% Output CSV filename
outFileName = [datestr(datetime) '.csv'];
% Print serial data (debug purpose)
printSerial = false;

%% Initialization 
baudRate = 115200;

numPlotPoints = floor(plotPeriod*1000/acquisitionPeriod);
numMaxPoints = floor(maxPeriod*1000/acquisitionPeriod);
pointIdx = numPlotPoints;

serialPort = serial(serialPortDevice,'BaudRate',baudRate);

% Vectors for plots
timeVector = (-numPlotPoints:-1)*acquisitionPeriod/1000;
busVVector = zeros(numPlotPoints,1);
shuntVVector = zeros(numPlotPoints,1);
loadVVector = zeros(numPlotPoints,1);
currentVector = zeros(numPlotPoints,1);
busPowerVector = zeros(numPlotPoints,1);
loadPowerVector = zeros(numPlotPoints,1);

% Vectors for CSV
busVVectorCSV = zeros(numMaxPoints+numPlotPoints,1);
shuntVVectorCSV = zeros(numMaxPoints+numPlotPoints,1);
loadVVectorCSV = zeros(numMaxPoints+numPlotPoints,1);
currentVectorCSV = zeros(numMaxPoints+numPlotPoints,1);
busPowerVectorCSV = zeros(numMaxPoints+numPlotPoints,1);
loadPowerVectorCSV = zeros(numMaxPoints+numPlotPoints,1);

%% Initialize plots
fig = figure(1);
subplot(2,3,1);
busVPlot = plot(timeVector,busVVector);
busVPlot.XDataSource = 'timeVector';
busVPlot.YDataSource = 'busVVector';
ylabel('Bus Voltage [V]');
xlabel('Time [s]');
ylim([0 6]);

subplot(2,3,2);
shuntVPlot = plot(timeVector,shuntVVector);
shuntVPlot.XDataSource = 'timeVector';
shuntVPlot.YDataSource = 'shuntVVector';
ylabel('Shunt Voltage [mV]');
xlabel('Time [s]');
ylim([0 100]);

subplot(2,3,3);
loadVPlot = plot(timeVector,loadVVector);
loadVPlot.XDataSource = 'timeVector';
loadVPlot.YDataSource = 'loadVVector';
ylabel('Load Voltage [V]');
xlabel('Time [s]');
ylim([0 6]);

subplot(2,3,4);
currentPlot = plot(timeVector,currentVector);
currentPlot.XDataSource = 'timeVector';
currentPlot.YDataSource = 'currentVector';
ylabel('Current Drain [mA]');
xlabel('Time [s]');
ylim([0 1500]);

subplot(2,3,5);
busPowerplot = plot(timeVector,busPowerVector);
busPowerplot.XDataSource = 'timeVector';
busPowerplot.YDataSource = 'busPowerVector';
ylabel('Bus Power [W]');
xlabel('Time [s]');
ylim([0 5]);

subplot(2,3,6);
loadPowerPlot = plot(timeVector,loadPowerVector);
loadPowerPlot.XDataSource = 'timeVector';
loadPowerPlot.YDataSource = 'loadPowerVector';
ylabel('Load Power [W]');
xlabel('Time [s]');
ylim([0 5]);

%% Initialize port
fopen(serialPort);
readasync(serialPort);

% Read the init line
readData = fscanf(serialPort);
disp(readData);

% Read the legend line
readData = fscanf(serialPort);
disp(readData);

%% Continuous capture
while (ishandle(fig) && pointIdx <= numMaxPoints)
    %readasync(serialPort);
    readData = fscanf(serialPort);
    if (printSerial)
        disp(readData);
    end
    
    valuesStr = strsplit(readData,',');
    
    if (size(valuesStr,2)<4)
        continue
    end
    
    % Extract Data
    busV = str2double(valuesStr{1}); %V
    shuntV = str2double(valuesStr{2}); %mV
    loadV = str2double(valuesStr{3}); %V
    current = str2double(valuesStr{4}); %mA
    busPower = busV*current/1000; %W
    loadPower = loadV*current/1000; %W
    
    if (isnan(busV) || isnan(shuntV) || isnan(loadV) ||isnan(current))
        continue
    end

    % Store data
    busVVectorCSV(pointIdx) = busV;
    shuntVVectorCSV(pointIdx) = shuntV;
    loadVVectorCSV(pointIdx) = loadV;
    currentVectorCSV(pointIdx) = current;
    busPowerVectorCSV(pointIdx) = busPower;
    loadPowerVectorCSV(pointIdx) = loadPower;

    % Plot data
    busVVector = busVVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    shuntVVector = shuntVVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    loadVVector = loadVVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    currentVector = currentVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    busPowerVector = busPowerVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    loadPowerVector = loadPowerVectorCSV(pointIdx-numPlotPoints+1:pointIdx);
    timeVector = timeVector + acquisitionPeriod/1000;

    pointIdx = pointIdx + 1;

    for idx = 1:6
        subplot(2,3,idx);
        xlim([min(timeVector),max(timeVector)]);
    end
    refreshdata;
    drawnow;
       
end

fclose(serialPort);

%% Save CSV

disp(['Saving data to ' outFileName]);

busVVectorCSV = busVVectorCSV(numPlotPoints:pointIdx-1);
shuntVVectorCSV = shuntVVectorCSV(numPlotPoints:pointIdx-1);
loadVVectorCSV = loadVVectorCSV(numPlotPoints:pointIdx-1);
currentVectorCSV = currentVectorCSV(numPlotPoints:pointIdx-1);
busPowerVectorCSV = busPowerVectorCSV(numPlotPoints:pointIdx-1);
loadPowerVectorCSV = loadPowerVectorCSV(numPlotPoints:pointIdx-1);

csvwrite(outFileName,[...
    busVVectorCSV,shuntVVectorCSV,loadVVectorCSV,...
    currentVectorCSV,busPowerVectorCSV,loadPowerVectorCSV]);