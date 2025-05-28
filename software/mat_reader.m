%octave stuff only
more off;

%constants
no=2;
weak=4;

%variables 
i_CalculationWindow = 5;
filename = strcat('log',datestr(now,'dd.mm.yyyy'),'.xlsx');
errors=0;
test_duration=120;%seconds
%start matlab timer
tic;
passed_time=toc;
i=0;

while passed_time<test_duration
 passed_time=toc;
 i=i+1;
 %back compatibility function, available on octave too..
 [data, success]=urlread('http://192.168.4.1');
 
 %Now we check the validity of the response

 %preset valid_string as negative response
 valid_string=0;
 if success==1 && length(data)==84
  if strcmp(data(1:23),'PIC response: Hello! C=') && strcmp(data(83:84),' B')
   valid_string=1;
  end
 end

 %if response is valid proceed, elsewhere alert and repeat immediately
 if valid_string==1
  data
  times(i)=passed_time;
  
  R1 = str2num(data(31:33));
  R2 = str2num(data(38:40));
  R3= str2num(data(45:47));
  R4 = str2num(data(52:54));
  r1(i)=str2num(data(1,59:61));
  r2(i)=str2num(data(1,66:68));
  r3(i)=str2num(data(1,73:75));
  r4(i)=str2num(data(1,80:82));
  D1(i)=R1-r1(i);
  D2(i)=R2-r2(i);
  D3(i)=R3-r3(i);
  D4(i)=R4-r4(i);

  %Please can you comment the name of those variables? I did not catch why D2 is
  %not considered
  %if I understood last values are as in the following.
  CT_val= mean(D4(max([i-i_CalculationWindow,1]):i));
  NG_val= mean(D3(max([i-i_CalculationWindow,1]):i));
  IC_val= mean(D1(max([i-i_CalculationWindow,1]):i));
  
  
  if(CT_val>no)
   if(CT_val>weak)
    CT='pos'
   else
    CT='weak'
   end
  else
   CT='no'
  end

  if(NG_val>no)
   if(NG_val>weak)
    NG='pos'
   else
    NG='weak'
   end
  else
   NG='no'
  end

  if(IC_val>no)
   if(IC_val>weak)
    IC='pos'
   else
    IC='weak'
   end
  else
   IC='no'
  end
    
  %wait some ms, this values seems reduced the error ratio, I can reduce
  %such a delay and increase accordly the speed of the micro if needed. 
  pause(1.200)
 else
  errors=errors+1;
  disp(['Data read error n.',num2str(errors),'/',num2str(i)])
  %wait some ms
  pause(.900)
 end
 v_err(i)=errors;
 plot(v_err(1:i))
end
disp(['Total number of Data read error: ',num2str(errors)])

