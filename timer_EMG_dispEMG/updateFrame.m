function [stop_flag,state_new_out]=updateFrame(command,state_old)
% state contains the position of the previous point (:,1) and
% the current point (:,2).
stop_flag=false;
state_new_out.num_of_run=state_old.num_of_run;
state_new_out.user1_min=state_old.user1_min;
state_new_out.user1_max=state_old.user1_max;
state_new_out.user2_min=state_old.user2_min;
state_new_out.user2_max=state_old.user2_max;
state_new_out.board=state_old.board;
state_new_out.datablock=state_old.datablock;
state_new_out.sig_plot=state_old.sig_plot;
state_new_out.raw_plot=state_old.raw_plot;

gameplot=state_old.gameplot;
state_ball=state_old.state.ball;
state_bar1=state_old.state.bar1;
state_bar2=state_old.state.bar2;

bar_speed=10;
geometry.length=1000;
geometry.width=618;
geometry.paddle_len=120;
geometry.ball_r=10;
geometry.bar1_position=[100,state_bar1(2)];
geometry.bar2_position=[900,state_bar2(2)];
geometry.bar_length=250;
geometry.bar_width=15;
%% calculate new bar position
if ((state_bar1(2)-bar_speed>0 && state_bar1(2)+geometry.bar_length+bar_speed<geometry.width)||...
        (state_bar1(2)-bar_speed<=0&&command(1)>0)||...
        (state_bar1(2)+geometry.bar_length+bar_speed>=geometry.width&&command(1)<=0))
    geometry.bar1_position(2)=state_bar1(2)+command(1)*bar_speed;
end
if (state_bar2(2)-bar_speed>0 && state_bar2(2)+geometry.bar_length+bar_speed<geometry.width||...
        (state_bar2(2)-bar_speed<=0&&command(2)>0)||...
        (state_bar2(2)+geometry.bar_length+bar_speed>=geometry.width&&command(2)<=0))
    geometry.bar2_position(2)=state_bar2(2)+command(2)*bar_speed;
end

%% calculate next position
state_new(:,1)=state_ball(:,2);
hit_flag=hitwall(state_ball,geometry);
if (hit_flag)
    switch hit_flag
        case 1
            stop_flag=true;
        case 2
            stop_flag=true;
        case 3
            state_new(1,2)=state_ball(1,2)+state_ball(1,2)-state_ball(1,1);
            state_new(2,2)=state_ball(2,1);
        case 4
            state_new(1,2)=state_ball(1,2)+state_ball(1,2)-state_ball(1,1);
            state_new(2,2)=state_ball(2,1);
        case 5
            state_new(1,2)=state_ball(1,1);
            state_new(2,2)=state_ball(2,2)+state_ball(2,2)-state_ball(2,1)...
                + command(1)*(abs(state_ball(2,2)-state_ball(2,1)-bar_speed)/3+rand());
        case 6
            state_new(1,2)=state_ball(1,1);
            state_new(2,2)=state_ball(2,2)+state_ball(2,2)-state_ball(2,1)...
                + command(2)*(abs(state_ball(2,2)-state_ball(2,1)-bar_speed)/3+rand());
    end
else
    state_new(:,2)=state_ball(:,2)+state_ball(:,2)-state_ball(:,1);
end

if(~stop_flag)
    circle_h.x=state_new(1,2);
    circle_h.y=state_new(2,2);
    circle_h.r=geometry.ball_r;
    [X,Y] = drawCircle_data(circle_h);
    [x1,y1,x2,y2] = drawBarData(geometry);
    set(gameplot(1),'Xdata',X,'Ydata',Y)
    set(gameplot(2),'Xdata',x1,'Ydata',y1)
    set(gameplot(3),'Xdata',x2,'Ydata',y2)
    drawnow
end

state_new_out.gameplot=gameplot;
state_new_out.state.ball=state_new;
state_new_out.state.bar1=geometry.bar1_position;
state_new_out.state.bar2=geometry.bar2_position;


end

function [myX,myY] = drawCircle_data(circ)
angle = 0:pi/100:2*pi;
myX = circ.r*cos(angle)+circ.x;
myY = circ.r*sin(angle)+circ.y;
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

function hit=hitwall(state,geometry)
hit_left=state(1,2)<geometry.ball_r; %1
hit_right=state(1,2)>geometry.length-geometry.ball_r; %2
hit_bottom=state(2,2)<geometry.ball_r; %3
hit_top=state(2,2)>geometry.width-geometry.ball_r;%4
hit_bar1=(state(1,2)<geometry.ball_r+geometry.bar1_position(1)+geometry.bar_width)&&...%5
    (state(1,2)>geometry.bar1_position(1)+geometry.bar_width)&&...
    (state(2,2)>geometry.bar1_position(2)-geometry.ball_r)&&...
    (state(2,2)<geometry.bar1_position(2)+geometry.bar_length+geometry.ball_r)&&...
    (state(1,1)>state(1,2));
hit_bar2=(state(1,2)>-geometry.ball_r+geometry.bar2_position(1))&&...%6
    (state(1,2)<geometry.bar2_position(1))&&...
    (state(2,2)>geometry.bar2_position(2)-geometry.ball_r)&&...
    (state(2,2)<geometry.bar2_position(2)+geometry.bar_length+geometry.ball_r)&&...
    (state(1,1)<state(1,2));
hit=find([hit_left,hit_right,hit_bottom,hit_top,hit_bar1,hit_bar2]==true);

end