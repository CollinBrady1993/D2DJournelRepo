
Nr = 48;
for Nu = 1:24
    for Np = 1:Nu
        for r = 1:min(Nu,Nr)
            Nu
            Np
            r
            datestr(now)
            A = makeA(Nu,Np,r);
            
            filename = strcat('Nu',num2str(Nu),',','Np',num2str(Np),',','r',num2str(r),'.csv');
            
            csvwrite(filename,A)
            
        end
    end
end
