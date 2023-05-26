x = [0];
a = 0;
c = 1;

color = ["#1C27E9" "#1CE9E4" "#B7DC00" "#DA337F" "#DD5906" "#D81E37"];

for i=1:300
    %x = cat(1,x,[0]);
    if i<=100
        a=a+1;
    else
        a=a-1;
    end
    x = [0, a];
    y = [0, 0];
    switch a
        case 0
            c = 1;
        case 30
            c = 2;
        case 70
            c = 3;
        case -1
            c = 4;
        case -30
            c = 5;
        case -70
            c = 6;
    end
    plot(x,y,'color',color(c),'LineWidth',200)
    xticks([])
    yticks([])
    xlim([-150 150])
    ylim([-1 1])
    drawnow;
    
end
    