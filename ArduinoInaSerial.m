clear;
clc;

acquisitionPeriod = 200; %ms
numPointsInPlot = 100; %Number of point in plot window

maxPoints = 100000;
pointIdx = numPointsInPlot;

serialPortDevice = '/dev/tty.usbmodem1a1231';
baudRate = 115200;

serialPort = serial(serialPortDevice,'BaudRate',baudRate);

outFileName = [datestr(datetime) '.csv'];

% Vectors to store for graphs
timeVector = (-numPointsInPlot:-1)*acquisitionPeriod/1000;
busVVector = zeros(numPointsInPlot,1);
shuntVVector = zeros(numPointsInPlot,1);
loadVVector = zeros(numPointsInPlot,1);
currentVector = zeros(numPointsInPlot,1);
busPowerVector = zeros(numPointsInPlot,1);
loadPowerVector = zeros(numPointsInPlot,1);

% Vectors to store for csv
busVVectorCSV = zeros(maxPoints+numPointsInPlot,1);
shuntVVectorCSV = zeros(maxPoints+numPointsInPlot,1);
loadVVectorCSV = zeros(maxPoints+numPointsInPlot,1);
currentVectorCSV = zeros(maxPoints+numPointsInPlot,1);
busPowerVectorCSV = zeros(maxPoints+numPointsInPlot,1);
loadPowerVectorCSV = zeros(maxPoints+numPointsInPlot,1);

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
ylabel('Shunt Voltage [V]');
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

% Initialize port
fopen(serialPort);
readasync(serialPort);

% Read The init line
%readasync(serialPort);
readData = fscanf(serialPort);
disp(readData);

% Read the legend
%readasync(serialPort);
readData = fscanf(serialPort);
disp(readData);

while (ishandle(fig) && pointIdx <= maxPoints)
    %readasync(serialPort);
    readData = fscanf(serialPort);
    disp(readData);
    valuesStr = strsplit(readData,',');
    disp(valuesStr);
    
    % Extract Data
    busV = str2double(valuesStr(1)); %V
    shuntV = str2double(valuesStr(2)); %mV
    loadV = str2double(valuesStr(3)); %V
    current = str2double(valuesStr(4)); %mA
    busPower = busV*current/1000; %W
    loadPower = loadV*current/1000; %W

    % Store data
    busVVectorCSV(pointIdx) = busV;
    shuntVVectorCSV(pointIdx) = shuntV;
    loadVVectorCSV(pointIdx) = loadV;
    currentVectorCSV(pointIdx) = current;
    busPowerVectorCSV(pointIdx) = busPower;
    loadPowerVectorCSV(pointIdx) = loadPower;

    % Plot data
    busVVector = busVVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
    shuntVVector = shuntVVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
    loadVVector = loadVVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
    currentVector = currentVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
    busPowerVector = busPowerVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
    loadPowerVector = loadPowerVectorCSV(pointIdx-numPointsInPlot+1:pointIdx);
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
disp(['Saving data to ' outFileName]);

busVVectorCSV = busVVectorCSV(numPointsInPlot:pointIdx-1);
shuntVVectorCSV = shuntVVectorCSV(numPointsInPlot:pointIdx-1);
loadVVectorCSV = loadVVectorCSV(numPointsInPlot:pointIdx-1);
currentVectorCSV = currentVectorCSV(numPointsInPlot:pointIdx-1);
busPowerVectorCSV = busPowerVectorCSV(numPointsInPlot:pointIdx-1);
loadPowerVectorCSV = loadPowerVectorCSV(numPointsInPlot:pointIdx-1);

csvwrite(outFileName,[...
    busVVectorCSV,shuntVVectorCSV,loadVVectorCSV,...
    currentVectorCSV,busPowerVectorCSV,loadPowerVectorCSV]);