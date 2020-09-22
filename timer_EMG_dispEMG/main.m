%% change log
% 9:27pm main_func() diff1,diff2 sign is reversed.
%         process() command=sqrt(...) EMG amplitude propotional to force,
%                                        not power
%                    filter->filtfilt, zero padded and throw away first 100 points to get rid of
%                                        filter transients
%%
clear
if(~isequal(timerfindall,[]))
stop(timerfindall)
delete(timerfindall)% clear timer and workspace
end

framerate=1000; %fps
stop_flag=false;
state.ball=[517,514;440,440]; %initialize the position
state.bar1=[100;195];
state.bar2=[900;184];

circle_h.x=state.ball(1,2);
circle_h.y=state.ball(2,2);
circle_h.r=10;
circle_h.length=1000;
circle_h.width=618;
circle_h.bar1_position=state.bar1;
circle_h.bar2_position=state.bar2;
circle_h.bar_length=250;
circle_h.bar_width=15;
gameplot = drawCircle(circle_h);
xlim([1 1000])
ylim([1 618])

load 50HzLP.mat
global EMG_LP
EMG_LP=Num;

%%
global params
params = get_default_params();
disp ('Connecting to board. . .');
% Instantiate the rhd2000 driver.  Using the RHD2000 Matlab Toolbox
% almost always starts this way.
driver = rhd2000.Driver();
disp ('Connected.');
board = driver.create_board();
board.SamplingRate = params.sampling_rate;
datablock = rhd2000.datablock.DataBlock(board);
subplot(4,2,5)
raw_plot.user1=plot(linspace(0,180,360),zeros(1,360));
title('user1 raw')
ylim([-0.5 0.5])
subplot(4,2,7)
sig_plot.user1=plot(linspace(50,180,261),zeros(1,261));
title('user1 sig')
ylim([-0.5 0.5])
subplot(4,2,6)
raw_plot.user2=plot(linspace(0,180,360),zeros(1,360));
title('user2 raw')
ylim([-0.5 0.5])
subplot(4,2,8)
sig_plot.user2=plot(linspace(50,180,261),zeros(1,261));
title('user2 sig')
ylim([-0.5 0.5])
%board.run_continuously();
%%

pause(1) %wait the figure open

gamedata.state=state;%pass the initial state to the timer
gamedata.gameplot=gameplot;
gamedata.raw_plot=raw_plot;
gamedata.sig_plot=sig_plot;
gamedata.num_of_run=0;
gamedata.board=board;
gamedata.datablock=datablock;
t=createTimer(framerate,gamedata);
start(t)



function main_func(mTimer,~)
mTimer.UserData.num_of_run=mTimer.UserData.num_of_run+1;

    command=process(mTimer.UserData.datablock,mTimer.UserData.board,mTimer.UserData.raw_plot,mTimer.UserData.sig_plot);
    diff1=mTimer.UserData.user1_max-mTimer.UserData.user1_min;
    mean1=(mTimer.UserData.user1_min+mTimer.UserData.user1_max)/2;
    diff2=mTimer.UserData.user2_max-mTimer.UserData.user2_min;
    mean2=(mTimer.UserData.user2_min+mTimer.UserData.user2_max)/2;
    command(1)=(command(1)-mean1)/diff1*2; %% map to -1~1
    command(2)=(command(2)-mean2)/diff2*2;
    command(command > 1)=1;
    command(command <-1)=-1;

stop_flag=false;
if (mTimer.UserData.num_of_run==1)
      [stop_flag,mTimer.UserData]=updateFrame(command,mTimer.UserData);

    mTimer.UserData.num_of_run=0;
end
    
    
    if(stop_flag)
        mTimer.UserData.board.stop();
        mTimer.UserData.board.flush();
        clear datablock;
        endgame();
    end
end

function calibrate(mTimer,~)
disp('Calibrating user1.')
input('user1 min')
mTimer.UserData.board.run_continuously();
command=process(mTimer.UserData.datablock,mTimer.UserData.board,mTimer.UserData.raw_plot,mTimer.UserData.sig_plot);
mTimer.UserData.user1_min=command(1);
        mTimer.UserData.board.stop();
        mTimer.UserData.board.flush();
input('user1 max')
        mTimer.UserData.board.run_continuously();
command=process(mTimer.UserData.datablock,mTimer.UserData.board,mTimer.UserData.raw_plot,mTimer.UserData.sig_plot);
mTimer.UserData.user1_max=command(1);
        mTimer.UserData.board.stop();
        mTimer.UserData.board.flush();
disp('Calibrating user2.')
input('user2 min')
        mTimer.UserData.board.run_continuously();
command=process(mTimer.UserData.datablock,mTimer.UserData.board,mTimer.UserData.raw_plot,mTimer.UserData.sig_plot);
mTimer.UserData.user2_min=command(2);
        mTimer.UserData.board.stop();
        mTimer.UserData.board.flush();
input('user2 max')
        mTimer.UserData.board.run_continuously();
command=process(mTimer.UserData.datablock,mTimer.UserData.board,mTimer.UserData.raw_plot,mTimer.UserData.sig_plot);
mTimer.UserData.user2_max=command(2);
        mTimer.UserData.board.stop();
        mTimer.UserData.board.flush();
        figure(1);
        pause(6)
        mTimer.UserData.board.run_continuously();
end

function t = createTimer(framerate,gamedata)
t = timer; %create a timer object
t.UserData=gamedata;
t.StartFcn = @calibrate;
t.TimerFcn = @main_func; %indicate which function needs
%to be exicuted
t.Period = round(1/framerate,3); % min precision of time is 1ms
%t.TasksToExecute = ceil(secondsWorkTime/t.Period); %set max time in future
t.ExecutionMode = 'fixedRate';
t.BusyMode='drop';
end 

function command=process(datablock,board,raw_plot,sig_plot)
global EMG_LP
global params
datablock.read_next(board);
signal1 = datablock.Chips{params.signal_datasource1}.Amplifiers(params.signal_channel1, :);
reference1 = datablock.Chips{params.reference_datasource1}.Amplifiers(params.reference_channel1, :);
% Calculate the 'raw' plot, as reference-corrected signal, in mV
raw1 = signal1-reference1;
raw1 = raw1 * 1000; % convert to mV
sig1=filtfilt(EMG_LP,1,[raw1 raw1 raw1 raw1 raw1 raw1]);
set(raw_plot.user1,'Ydata',[raw1 raw1 raw1 raw1 raw1 raw1])
set(sig_plot.user1,'Ydata',sig1(100:end))


signal2 = datablock.Chips{params.signal_datasource2}.Amplifiers(params.signal_channel2, :);
reference2 = datablock.Chips{params.reference_datasource2}.Amplifiers(params.reference_channel2, :);
% Calculate the 'raw' plot, as reference-corrected signal, in mV
raw2 = signal2-reference2;
raw2 = raw2 * 1000; % convert to mV
sig2=filtfilt(EMG_LP,1,[raw2 raw2 raw2 raw2 raw2 raw2]);
set(raw_plot.user2,'Ydata',[raw2 raw2 raw2 raw2 raw2 raw2])
set(sig_plot.user2,'Ydata',sig2(100:end))

command=[0,0]; % classification
command(1)=sqrt(sum(sig1(100:end).^2)/60)*2;
command(2)=sqrt(sum(sig2(100:end).^2)/60)*2;
if (board.FIFOPercentageFull > 1)
    % Start showing warnings if we're lagging
    display(sprintf('WARNING: board FIFO is %g%% full', ...
        board.FIFOPercentageFull));
end
end

function h = drawCircle(circ)
cla;
angle = 0:pi/100:2*pi;
myX = circ.r*cos(angle)+circ.x;
myY = circ.r*sin(angle)+circ.y;
[x1,y1,x2,y2] = drawBarData(circ);
subplot(4,2,[1,2,3,4])
h = plot(myX,myY,'k',x1,y1,'k',x2,y2,'k');
end

function [x1,y1,x2,y2] = drawBarData(bar)
ax1 = bar.bar1_position(1);
ay1 = bar.bar1_position(2);
ax2 = bar.bar2_position(1);
ay2 = bar.bar2_position(2);
w = bar.bar_length;
l = bar.bar_width;
x1 = [ax1,ax1+l,ax1+l,ax1,ax1];
y1 = [ay1,ay1,ay1+w,ay1+w,ay1];
x2 = [ax2,ax2+l,ax2+l,ax2,ax2];
y2 = [ay2,ay2,ay2+w,ay2+w,ay2];
end

function endgame()

    if(~isequal(timerfindall,[]))
        stop(timerfindall)
        delete(timerfindall)% clear timer and workspace
    end
    clf;
    imshow('gameover.jpg')
end

function params = get_default_params()
% Gets default parameters
%
% See real_time_analysis() for how to override them

    % Sampling rate for the board
    params.sampling_rate = rhd2000.SamplingRate.rate2000;
    
    % Threshold for spike detection - anything crossing the threshold is
    % considered to be a spike.
    %params.threshold_mV = 0.1;

    % Signal and reference
    % Datasources:
    %     1 = Port A, MISO 1
    %     2 = Port A, MISO 2
    %     3 = Port B, MISO 1
    %     4 = Port B, MISO 2
    %     5 = Port C, MISO 1
    %     6 = Port C, MISO 2
    %     7 = Port D, MISO 1
    %     8 = Port D, MISO 2
    % Channel is 1-16 for an RHD2216 chip, 1-32 for an RHD2132, or 1-64 for
    % an RHD2164 chip.
    params.signal_datasource1 = 1;
    params.signal_channel1 = 13   +1;  % +1 because matlab indexing
    params.reference_datasource1 = 1;
    params.reference_channel1 = 22   +1;% +1 because matlab indexing
    
    
    params.signal_datasource2 = 3;
    params.signal_channel2 = 9   +1;   % +1 because matlab indexing
    params.reference_datasource2 = 3;
    params.reference_channel2 = 13   +1;% +1 because matlab indexing

    % Run for this number of seconds before stopping.  Note that this
    % refers to the main loop; attaching to the board takes several seconds
    % and is not counted in this number
    params.num_seconds = 10;

    % Number of points to display in the plots.  Must be divisible by 60,
    % as each datablock contains 60 points.
    params.num_points = 2040;

    % Refresh the display refresh_freq times a second.  If you're doing
    % something computationally intensive, you can lower this number; the
    % display will be more sluggish, but the computation will keep going at
    % full speed.  If this number is too high, the computer will have
    % trouble keeping up with the board, and you'll start getting warnings
    % and then errors about the FIFO filling up.
    params.refresh_freq = 10; 
end
