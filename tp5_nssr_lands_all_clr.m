% 创建晴天条件下的tp5
clear all;
clc;

MODEL=[1,2,3,4,5,6]; %MODTRAN提供的六种大气廓线
% IHAZE=[1,4,5,6]; %定义四种气溶胶消光模式：乡村、海洋、城市、对流层
% VIS=[23,15,5,50]; %对应的能见度
IHAZE=[1,2,4,6]; %定义四种气溶胶消光模式：乡村、乡村、海洋、对流层
VIS=[23,5,15,50]; %对应的能见度

RSA=[0,30,60,90,120,150,180];
SZA=[0,10,20,30,40,50,60,70,80];
vza=[0,10,20,30,40,50,60]; %实际vza
% 计算MODTRAN需要的VZA
R = 6371.23; sensorHeight=705;
VZA=180 - asin(R * sin(deg2rad(vza))/(R + sensorHeight)) * 180/pi;

% 读取所有地类的名称
files=dir('E:\学术\MATLAB\NSSR\MODTRAN part\brdf_modis_read\3brdf_17lands_annual_aver\*.txt');
for i=1:length(files)
    fns{i}=files(i).name;  % fns是带后缀的名称
    %[filepath,name,ext] = fileparts(namei);
    nms{i}=fns{i};  % fns是带后缀的名称
    nms{i}(end-3:end)=[];  % nms是删除后缀的base文件名
end

%注意：之前VZA=[130](即实际观测天顶角为50°时，模拟结果总出错，因此改为48°)
wl=[0.466;0.553;0.646;0.855;1.243;1.632;2.119];
suff=repmat([2 1],7,1);
mkdir('17land_tp5_clr_annual_aver\');
for k=1:17
    p3=textread(['E:\学术\MATLAB\NSSR\MODTRAN part\brdf_modis_read\3brdf_17lands_annual_aver\',fns{k}]);
    p3=[wl,p3,suff];
    mkdir(['17land_tp5_clr_annual_aver\',nms{k}]);
    for r=1:length(RSA)
        for s=1:length(SZA)
            for v=1:length(VZA)
                tp5=['17land_tp5_clr_annual_aver\',nms{k},'\',nms{k},'_',num2str(r),num2str(s),num2str(v),'.tp5'];
                fid=fopen(tp5,'w');
                
                for i=1:length(MODEL)
                    for j=1:length(IHAZE)
                        %% card1
                        %format='(4A1,I1,A1,I4,10I5,1X,I4,F8.3,A7)'
                        fprintf(fid,['TMF ',num2str(MODEL(i)),' ','   2','    2   -1    0    0    0    0    0    0    0    1',' ','   1','   0.000','   BRDF\n']);
                        %倒数第三个1表示输出的tp6不包含大气廓线和光谱数据？
                        % card1A，open thrml sct
                        %format='(3A1, I3, F4.0,F10.3,2A10,2A1,4(1X,A1),F10.3,A1,F9.3,3F10.3,I10)'
                        fprintf(fid,'fff  8  0.   365.000                    0f f t t       0.000     0.000     0.000     0.000     0.000         0\n');
                        % card1A3, Instrument spectral response function
                        fprintf(fid,'DATA/GF5 b1-b6.flt\n'); %format='(A-256)'
                        
                        %% card2
                        %format='(A2, I3, A1, I4, A3, I2, 3I5, 5F10.5)'
                        fprintf(fid,'  ');
                        fprintf(fid,'%3d',IHAZE(j));
                        fprintf(fid,'    0    0    3');
                        fprintf(fid,'%5d',0);% ICLD，0晴天，1.2.3云天时card2a要设置
                        fprintf(fid,'    0');
                        fprintf(fid,'%10.5f',VIS(j));
                        fprintf(fid,'   0.00000   0.00000   0.00000   0.00200\n');%最后一个0.0000是DEM，可以进行改变
                        
                        %% card3
                        %format='(6F10.3, I5, 5X, 2F10.3)'
                        fprintf(fid,'   705.000     0.002');
                        fprintf(fid,'%10.3f',VZA(v));
                        fprintf(fid,'     0.000     0.000     0.000    0          0.000\n') ;
                        % card3A1 %format='(4I5)'
                        fprintf(fid,'   12    2   93    0\n');
                        % card3A2 %format='(8F10.3)'
                        fprintf(fid,'%10.3f',RSA(r));
                        fprintf(fid,'%10.3f',SZA(s));
                        fprintf(fid,'     0.000     0.000    10.500     0.000     0.000     0.000\n');
                        
                        %% card4
                        %   GF-5的wl=0.45~2.35μm
                        % 实际采用wl=0.4~2.45μm(按照flt的范围，较宽)
                        % format=' (4F10.0,2A1,A8,A7,I3,F10.0)'
                        fprintf(fid,'     4081.    25000.        1.        2.RM              T  1        0.\n');
                        % card4A
                        fprintf(fid,'1    0.000    0.000f    \n');
                        % card4B1,4B2
                        fprintf(fid,'Ross-Li\n');
                        fprintf(fid,'7 0.0 90.0\n');
                        % card4B3,BRDF模型的参数
                        
                        fprintf(fid,[num2str(p3(1,:)),'\n']);
                        fprintf(fid,[num2str(p3(2,:)),'\n']);
                        fprintf(fid,[num2str(p3(3,:)),'\n']);
                        fprintf(fid,[num2str(p3(4,:)),'\n']);
                        fprintf(fid,[num2str(p3(5,:)),'\n']);
                        fprintf(fid,[num2str(p3(6,:)),'\n']);
                        fprintf(fid,[num2str(p3(7,:)),'\n']);
                        
                        %% card5
                        if (i == length(MODEL)) && (j == length(IHAZE))
                            fprintf(fid,'%5d\n',0);% format='(I5)'
                        else
                            fprintf(fid,'%5d\n',1);% format='(I5)'
                        end
                    end
                end
                fclose(fid);
            end
        end
    end
end

%% 获取tp5list
for k=1:17
    files=dir(['17land_tp5_clr_annual_aver\',nms{k},'\','*.tp5']);
    for i=1:length(files)
        list{i}=files(i).name;
    end
    
    %[filepath,name,ext] = fileparts(list(1));
    fid=fopen(['17land_tp5_clr_annual_aver\',nms{k},'\','mod5root.in'],'w');
    fprintf(fid,'%s\r\n',list{:});
    %fprintf(fid,'%s\n',string(list));
    fclose(fid);
end
