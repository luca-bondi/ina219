clc;
%% Arduino INA219 data plot and storage
%  Acquisition ends on figure close or maxPeriod reached

%% Parameters
% Select the plots to show: busV shuntV loadV current busPower loadPower
plotsFlag = [0 0 0 0 0 1];
% Refresh period for plots period period according to Arduino code
refreshPeriod = 500; %ms
% Interval shown in plots
plotPeriod = 60; %s
% Points of mean when showing data
pointMean = 100;
% Maximum recordable interval (to preallocate memory)
maxPeriod = 3600; %s
% Arduino serial port device
serialPortDevice = '/dev/tty.usbmodem1a12411';
% Output CSV filename
%outFileName = [datestr(datetime) '.csv'];
outFileName = ['capture.csv'];

%% Initialization 
baudRate = 115200;

lastPlotUpdateTimestamp = 0;

plotsNum = sum(plotsFlag);
plotsRows = floor(sqrt(plotsNum));
plotsCols = ceil(plotsNum/plotsRows);

% Lower bound for acquisition period
acquisitionPeriod = 5;

numInitPlotPoints = floor(plotPeriod*1000/acquisitionPeriod);
numMaxPoints = floor(maxPeriod*1000/acquisitionPeriod);
pointIdx = numInitPlotPoints;

serialPort = serial(serialPortDevice,'BaudRate',baudRate);

% Vectors for plots
timeVector = (-numInitPlotPoints:-1)*acquisitionPeriod/1000;
busVVector = zeros(numInitPlotPoints,1);
shuntVVector = zeros(numInitPlotPoints,1);
loadVVector = zeros(numInitPlotPoints,1);
currentVector = zeros(numInitPlotPoints,1);
busPowerVector = zeros(numInitPlotPoints,1);
loadPowerVector = zeros(numInitPlotPoints,1);
markerVector = zeros(numInitPlotPoints,1);

% Vectors for CSV
timeVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
busVVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
shuntVVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
loadVVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
currentVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
busPowerVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
loadPowerVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);
markerVectorCSV = zeros(numMaxPoints+numInitPlotPoints,1);

%% Initialize plots
fig = figure(1);

set(fig,'KeyPressFcn','markerVectorCSV(pointIdx-pointMean:pointIdx-1)=1000;disp(mean(loadPowerVectorCSV(pointIdx-pointMean:pointIdx-1)))');

plotIdx = 1;

if plotsFlag(1)
    subplot(plotsRows,plotsCols,plotIdx);
    busVPlot = plot(timeVector,busVVector);
    busVPlot.XDataSource = 'timeVector';
    busVPlot.YDataSource = 'busVVector';
    hold on;
    busVPlotMarker = plot(timeVector,markerVector);
    busVPlotMarker.XDataSource = 'timeVector';
    busVPlotMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Bus Voltage [V]');
    xlabel('Time [s]');
    ylim([0 5.5]);
    plotIdx = plotIdx + 1;
end

if plotsFlag(2)
    subplot(plotsRows,plotsCols,plotIdx);
    shuntVPlot = plot(timeVector,shuntVVector);
    shuntVPlot.XDataSource = 'timeVector';
    shuntVPlot.YDataSource = 'shuntVVector';
    hold on;
    shuntVPlotMarker = plot(timeVector,markerVector);
    shuntVPlotMarker.XDataSource = 'timeVector';
    shuntVPlotMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Shunt Voltage [mV]');
    xlabel('Time [s]');
    ylim([0 100]);
    plotIdx = plotIdx + 1;
end

if plotsFlag(3)
    subplot(plotsRows,plotsCols,plotIdx);
    loadVPlot = plot(timeVector,loadVVector);
    loadVPlot.XDataSource = 'timeVector';
    loadVPlot.YDataSource = 'loadVVector';
    hold on;
    loadVPlotMarker = plot(timeVector,markerVector);
    loadVPlotMarker.XDataSource = 'timeVector';
    loadVPlotMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Load Voltage [V]');
    xlabel('Time [s]');
    ylim([0 5.5]);
    plotIdx = plotIdx + 1;
end

if plotsFlag(4)
    subplot(plotsRows,plotsCols,plotIdx);
    currentPlot = plot(timeVector,currentVector);
    currentPlot.XDataSource = 'timeVector';
    currentPlot.YDataSource = 'currentVector';
    hold on;
    currentMarker = plot(timeVector,markerVector);
    currentMarker.XDataSource = 'timeVector';
    currentMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Current Drain [mA]');
    xlabel('Time [s]');
    ylim([0 800]);
    plotIdx = plotIdx + 1;
end

if plotsFlag(5)
    subplot(plotsRows,plotsCols,plotIdx);
    busPowerplot = plot(timeVector,busPowerVector);
    busPowerplot.XDataSource = 'timeVector';
    busPowerplot.YDataSource = 'busPowerVector';
    hold on;
    busPowerMarker = plot(timeVector,markerVector);
    busPowerMarker.XDataSource = 'timeVector';
    busPowerMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Bus Power [W]');
    xlabel('Time [s]');
    ylim([0 4]);
    plotIdx = plotIdx + 1;
end

if plotsFlag(6)
    subplot(plotsRows,plotsCols,plotIdx);
    loadPowerPlot = plot(timeVector,loadPowerVector);
    loadPowerPlot.XDataSource = 'timeVector';
    loadPowerPlot.YDataSource = 'loadPowerVector';
    hold on;
    loadPowerMarker = plot(timeVector,markerVector);
    loadPowerMarker.XDataSource = 'timeVector';
    loadPowerMarker.YDataSource = 'markerVector';
    grid on;
    ylabel('Load Power [W]');
    xlabel('Time [s]');
    ylim([0 4]);
    plotIdx = plotIdx + 1;
end

%% Initialize port
fopen(serialPort);
%readasync(serialPort);


%% Continuous capture
while (ishandle(fig) && pointIdx <= numMaxPoints)
    %readasync(serialPort);
    readData = fgetl(serialPort);
    
    valuesStr = strsplit(readData,',');
    
    if (size(valuesStr,2)<5)
        continue
    end
    
    % Extract Data
    timestamp = str2double(valuesStr{1}); %ms
    busV = str2double(valuesStr{2}); %V
    shuntV = str2double(valuesStr{3}); %mV
    loadV = str2double(valuesStr{4}); %V
    current = str2double(valuesStr{5}); %mA
    busPower = busV*current/1000; %W
    loadPower = loadV*current/1000; %W
    
    if (isnan(timestamp) ||isnan(busV) || isnan(shuntV) || isnan(loadV) ||isnan(current))
        continue
    end

    % Store data
    timeVectorCSV(pointIdx) = timestamp;
    busVVectorCSV(pointIdx) = busV;
    shuntVVectorCSV(pointIdx) = shuntV;
    loadVVectorCSV(pointIdx) = loadV;
    currentVectorCSV(pointIdx) = current;
    busPowerVectorCSV(pointIdx) = busPower;
    loadPowerVectorCSV(pointIdx) = loadPower;

    if (timestamp > lastPlotUpdateTimestamp + refreshPeriod)
        lastPlotUpdateTimestamp = timestamp;
        % Plot data
        plotPointsIdxs = find(timeVectorCSV(1:pointIdx) > (timestamp - plotPeriod*1000));
        
        timeVector = timeVectorCSV(plotPointsIdxs)/1000;
        busVVector = busVVectorCSV(plotPointsIdxs);
        shuntVVector = shuntVVectorCSV(plotPointsIdxs);
        loadVVector = loadVVectorCSV(plotPointsIdxs);
        currentVector = currentVectorCSV(plotPointsIdxs);
        busPowerVector = busPowerVectorCSV(plotPointsIdxs);
        loadPowerVector = loadPowerVectorCSV(plotPointsIdxs);
        markerVector = markerVectorCSV(plotPointsIdxs);

        for idx = 1:plotsNum
            subplot(plotsRows,plotsCols,idx);
            xlim([min(timeVector),max(timeVector)]);
        end
        refreshdata;
        drawnow;
    end
    
    pointIdx = pointIdx + 1;
       
end

fclose(serialPort);

%% Save CSV

disp(['Saving data to ' outFileName]);

timeVectorCSV = timeVectorCSV(numInitPlotPoints:pointIdx-1);
busVVectorCSV = busVVectorCSV(numInitPlotPoints:pointIdx-1);
shuntVVectorCSV = shuntVVectorCSV(numInitPlotPoints:pointIdx-1);
loadVVectorCSV = loadVVectorCSV(numInitPlotPoints:pointIdx-1);
currentVectorCSV = currentVectorCSV(numInitPlotPoints:pointIdx-1);
busPowerVectorCSV = busPowerVectorCSV(numInitPlotPoints:pointIdx-1);
loadPowerVectorCSV = loadPowerVectorCSV(numInitPlotPoints:pointIdx-1);
markerVectorCSV = markerVectorCSV(numInitPlotPoints:pointIdx-1);

csvwrite(outFileName,[...
    timeVectorCSV,busVVectorCSV,shuntVVectorCSV,loadVVectorCSV,...
    currentVectorCSV,busPowerVectorCSV,loadPowerVectorCSV,markerVectorCSV]);