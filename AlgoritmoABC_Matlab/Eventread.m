function [Task_label,Time_duration,Task_sym,strArray] =Eventread(pathname,filename)
Task_label=[];
Time_duration=[];
Task_sym=[];
%%  Each annotation includes one of three codes (T0, T1, or T2):
%    T0 corresponds to rest
%    T1 corresponds to onset of motion (real or imagined) of
%       the left fist (in runs 3, 4, 7, 8, 11, and 12)
%        both fists (in runs 5, 6, 9, 10, 13, and 14)
%    T2 corresponds to onset of motion (real or imagined) of
%        the right fist (in runs 3, 4, 7, 8, 11, and 12)
%        both feet (in runs 5, 6, 9, 10, 13, and 14)


formatSpec = '%6s%5s%12s%19s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%10s%s%[^\n\r]';
%% Open the text file.
fileID = fopen([pathname,filename,'.event'],'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'TextType', 'string',  'ReturnOnError', false);
fclose(fileID);
strArray=dataArray;
temp=[];
for i=1:size(dataArray,2)
    if size(dataArray{1,i},1)~=0
    temp=[temp,dataArray{1,i}];
    end
end
Temp_index=find(temp==' duration:');
if size(Temp_index,2)~=0
   Task_index=Temp_index-1;
   Time_index=Temp_index+1;
for i=1:size(Temp_index,2)
    temp1=char(temp(Task_index(i)));
    Task_sym{i,1}=temp1(end-1:end);
    Task_label{i,1}=str2num(temp1(end));
    
    temp2=char(temp(Time_index(i)));
    Time_duration{i,1}=str2num(temp2(1:4));
end
Task_label=cell2mat(Task_label);
Time_duration=cell2mat(Time_duration);
end
end

