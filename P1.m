clear;
close all;
clc;


tic %inicia contador, acaba en toc

% % % % %  Ranuras=[0 0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 1
% % % % %           0 0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 2
% % % % %           0 0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 3
% % % % %           0 0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 4     %1 ==Rx 2==Tx
% % % % %           0 0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 5
% % % % %           0 1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ; %Grado 6
% % % % %           1 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;]; %Grado 7
% % % % 
% % % %  Ranuras=[0 0 0 0 0 0 1 2 ; %Grado 1
% % % %           0 0 0 0 0 1 2 0 ; %Grado 2
% % % %           0 0 0 0 1 2 0 0 ; %Grado 3
% % % %           0 0 0 1 2 0 0 0 ; %Grado 4     %1 ==Rx 2==Tx
% % % %           0 0 1 2 0 0 0 0 ; %Grado 5
% % % %           0 1 2 0 0 0 0 0 ; %Grado 6
% % % %           1 2 0 0 0 0 0 0 ;]; %Grado 7


%definicion de variables duante la ventana de Backoff
DIFS = 10e-3; % Espacio entre tramas diferencial 
SIFS = 5e-3; % Espacio entre tramas (debido a que la Tx no es instantanea)
durRTS = 11e-3; %ready to send
durCTS = 11e-3; %confirmacion, listo para recibir paquetes
durACK = 11e-3; %paquetes de control
durDATA = 43e-3 ; %paquetes de datos (un solo paquete)
sigma = 1e-3 ; %duracion de cada miniranura

I = 7; % numero de grados
K = 15; %Tamaño maximo del buffer
Epsilon = 18; %Numero de ranuras sleep 

W = [ 16, 32, 64, 128, 256]; %Maximo numero de miniranuras
N = [ 5, 10, 15, 20]; %Numero de nodos por grado
lambda = [ 0.0005, 0.005, 0.03 ] ; % Tasa de generacion de paquetes por segundo


%indices de valores de miniranuras, N°de nodos por grado y del valor de lambda
W_index=3;
N_index=2;
lambda_index=3;

%duracion ranura
T = (sigma.*W(W_index))+ DIFS + 3*SIFS + durRTS+ durCTS+ durDATA + durACK; %%6000 ciclos
%T=durDATA+durRTS+durCTS+DIFS+durACK+(sigma.*W(W_index))+(3*SIFS); %2600 ciclos aprox

%Ciclo de trabajo 
Tc = (2+Epsilon-I).*T;%2+18-7=13

tsim = 0; % tiempo de simulacion inicia en 0
ta=-1; %valor para que ta sea menor a tsim al inicio del n ciclos


%inicializcion de buffers y contador paquetes
N_zeros=3000000; %tamaño array general del buffer y de otros
Buffer = zeros(K,N(N_index),I); %K,Nodos,Grados
Pkt=zeros(N_zeros,6);%cantidad de paquetes, susceptible a cambio en base a N_zeros [n_paquete,nodo,grado,ta,estado,tiempo_total]
backoff=zeros(N(N_index));%Array para los contendientes de paquetes a enviar

%arrays para guardar las estadisticas de los paquetes 
a_colisiones = zeros(1,7);
aux_buffer_ = 0;

%arrays para guardar las estadisticas de los paquetes cuando el buffer este lleno 
a_buffer_lleno=zeros(1,7);    
RetardoTotal = zeros(1, 7);
g_ExitososVsPerdidos = zeros(1, 2); %grafica de paquetes exitosos vs perdidos

%variables contadoras
n_ciclos=0;
n_paquetes=0;
n_colisiones=0;
n_paquetes_sink=0;%paquetes que llegaron al nodo sink
Throughput=zeros(1,I);%Paquetes exitosos por grado
ranuras=1;
grado_iterable=I;
Rx_flag=false;
Tx_flag=true;

%iniciamos asignando nodo a grado
lambda_2=lambda(lambda_index)*N(N_index)*I;


while n_ciclos <300000
    

    while ta<tsim 
        
        %nodo y grado aleatorio
        nodo_random=randi(N(N_index),1);
        grado_random= randi([2 I],1) ;
        %generacion de tiempo aleatorio
        U = (1e6*rand())/1e6; 
        nuevot = -(1/lambda_2)*log(1-U);
        ta=tsim+nuevot;
        
        if Buffer(15,nodo_random,grado_random)==0
            n_paquetes=n_paquetes+1;
            Pkt(n_paquetes,1) = n_paquetes;
            Pkt(n_paquetes,2) = nodo_random;
            Pkt(n_paquetes,3) = grado_random;
            Pkt(n_paquetes,4) = ta;
            Buffer(15,nodo_random,grado_random)=n_paquetes;
            Buffer(:,nodo_random,grado_random)=FIFO_buffer(Buffer(:,nodo_random,grado_random));
            
         
             %fprintf("grado:"+grado_random+" nodo:"+nodo_random+" n_paquete:"+n_paquetes+"\n");
        else
            for e=1:I
                if e==grado_random
                    a_buffer_lleno(e)=a_buffer_lleno(e)+1;%Aumenta contador de paquetes perdidos por buffer lleno
                end
            end
        end
  
    end
    
    
    
    %if Ranuras(grado_iterable,ranuras)==1  %Recepcion
        if Rx_flag==true
            if grado_iterable~=1 %nodo Sink, por lo tanto no hay porque agregar mas paquetes a otros nodos 
                if Buffer(15,Colision(1),grado_iterable)==0  %que la cola del buffer tenga espacio para otro paquete
                    Buffer(15,Colision(1),grado_iterable)=Aux_n_pkt;%se le asigna el numero del paquete tomado anteriormente
                    Buffer(:,Colision(1),grado_iterable)=FIFO_buffer(Buffer(:,Colision(1),grado_iterable));
                    Throughput(grado_iterable+1)=Throughput(grado_iterable+1)+1;
                else
                    %Verificacion buffer lleno  %1 exitoso 2=Colision 3=Buffer lleno
                    Pkt(Aux_n_pkt,5)=3;

                    %asignamos a cada grado, el numero de paquetes que encontraron el buffer lleno
                    for e=1:I
                        if e==(grado_iterable+1)
                        a_buffer_lleno(e)=a_buffer_lleno(e)+1;%Aumenta contador de paquetes perdidos por buffer lleno
                        end
                    end
                end
                
                
               % ranuras=ranuras+1;

            else %cuando grado=1
                    Pkt(Aux_n_pkt,6)=tsim;%indica el tiempo que tomo para que este lograra llegar al nodo sink
                    n_paquetes_sink=n_paquetes_sink+1;
                    Throughput(grado_iterable+1)=Throughput(grado_iterable+1)+1;
                  %  ranuras=ranuras+1;
                    

            end 
        else       
               % ranuras=ranuras+1;
                Rx_flag=false;
        end
         
  % end
    
    %Backoff
    
   % if Ranuras(grado_iterable,ranuras)==2   %Transmision

        if grado_iterable~=1
            backoff=zeros(1,N(N_index));
             for nodo=1:N(N_index)
            if Buffer(1,nodo,grado_iterable)~=0 %Si el paquete en 1 es diferente de 0 tiene un paquete por enviar
                backoff(nodo)=randi(W(W_index),1); %Deberia de ser randi([0 W(W_index)-1],1) pero para evitar confusiones con la inicialiacion se hace de 1 a W
            else
                backoff(nodo)=W(W_index)+1; %%Nunca se llegara a este valor, por lo cual se llena cuando no hay paquete que enviar o en el buffer  
            end
            end
            backoff_min=min(backoff(:));

            if backoff_min~=(W(W_index)+1)%%Indica que el valor minimo no es al que no se deberia de llegar

                Colision=find(backoff(:)==backoff_min);%Crear array con los valores que encuentra que tengan el mismo backoff
                len_colision=length(Colision);%longitud de datos en array Colision

                if len_colision==1  %Si hay mas de un valor, quiere decir que hay colision
                    Aux_n_pkt=Buffer(1,Colision(1),grado_iterable);%tomamos numero del primer paquete del nodo
                    Buffer(1,Colision(1),grado_iterable)=0;%Colocamos primer paquete en 0, que indica que esta vacio
                    Buffer(:,Colision(1),grado_iterable)=FIFO_buffer(Buffer(:,Colision(1),grado_iterable));
                    Rx_flag=true;

                    grado_iterable=grado_iterable-1; % 6 a 1
                    %ranuras=ranuras+1;
                    tsim=tsim+T;

                else
                    for col=1:len_colision
                        n_colisiones=n_colisiones+1;

                        %asignamos a cada grado, el numero de paquetes que
                        %colisionan en el
                        for e=1:I
                            if e==grado_iterable
                                a_colisiones(e)=a_colisiones(e)+1;%Aumenta contador de paquetes colisionados
                            end
                        end
                        aux_index=Colision(col);%toma el valor del indice del buffer(nodo) en array colisiones
                        aux_colision=Buffer(1,aux_index,grado_iterable);
                        Pkt(aux_colision,5)=2; %colocamos estado "2" de colision con otros paquetes
                        Buffer(1,aux_index,grado_iterable)=0;
                        Buffer(:,aux_index,grado_iterable)=FIFO_buffer(Buffer(:,aux_index,grado_iterable));
                    end
                    Rx_flag=false; %nada que recibir el grado 7
                    grado_iterable=grado_iterable-1; % 6 a 1
                    %ranuras=ranuras+1;
                    tsim=tsim+T;
                    
                end
            else
                grado_iterable=grado_iterable-1; % 6 a 1
                %ranuras=ranuras+1;
                tsim=tsim+T;
                Rx_flag=false;

            end
            
        else
            grado_iterable=I;
            n_ciclos=n_ciclos+1;
            tsim=tsim+T+Tc; 
            Rx_flag=false;
           % ranuras=1;
        end
       
   % end
    
end


%%impresion de estadisticas

%paquetes exitosos
figure()
stem( Throughput, 'LineWidth',2)
xlim([0 8])
title('Throughput')
ylabel('Paquetes transmitidos exitosamente')
xlabel('Grado')
grid on

figure()
labels = {'Grado 1', 'Grado 2', 'Grado 3', 'Grado 4', 'Grado 5', 'Grado 6','Grado 7'};
pie(Throughput, '%.3f%%')
title('Throughput')
lgd = legend(labels);

%grafica de coliciones por grado
figure()
stem(a_colisiones, 'LineWidth',2)
xlim([0 8])
title('Paquetes colisionados')
ylabel('# paquetes colisionados')
xlabel('Grado')
grid on

figure()
labels = {'Grado 1', 'Grado 2', 'Grado 3', 'Grado 4', 'Grado 5', 'Grado 6','Grado 7'};
pie(a_colisiones, '%.3f%%')
title('Paquetes colisionados')
lgd = legend(labels);

%grafica de los paquetes que encontaron el buffer lleno por grado
figure()
stem(a_buffer_lleno, 'LineWidth',2)
xlim([0 8])
title('Paquetes que encontraron el buffer lleno')
ylabel('# paquetes sin Tx')
xlabel('Grado')
grid on


figure()
labels = {'Grado 1', 'Grado 2', 'Grado 3', 'Grado 4', 'Grado 5', 'Grado 6','Grado 7'};
pie(a_buffer_lleno, '%.3f%%')
title('Paquetes que encontraron el buffer lleno')
lgd = legend(labels);

%Paquetes que fueron Tx y que se perdieron
figure()
stem(a_colisiones + a_buffer_lleno, 'LineWidth',2)
xlim([0 8])
title('Paquetes Tx perdidos por grado')
ylabel('# paquetes perdidos')
xlabel('Grado')
grid on

%paquetes perdidos por grado para una mejor comprension 
figure()
labels = {'Grado 1', 'Grado 2', 'Grado 3', 'Grado 4', 'Grado 5', 'Grado 6','Grado 7'};
pie(a_colisiones + a_buffer_lleno, '%.3f%%')
title('Paquetes Tx perdidos')
lgd = legend(labels);

%grafica de paquetes Tx exitosamente vs paquetes perdidos
g_ExitososVsPerdidos(1, 1) = sum(a_buffer_lleno)+ sum(a_colisiones);
g_ExitososVsPerdidos(1, 2) = sum(Throughput);

figure()
labels = {'Perdidos', 'Exitosamente'};
pie(g_ExitososVsPerdidos, '%.3f%%')
title('Paquetes Tx')
lgd = legend(labels);



toc %acaba contador


%%moviendo paquetes recien ingresados del buffer(15) al buffer mas cercano
%%al inicio que no este ocupado
function [Buffer]=FIFO_buffer(Buffer)

Buffer=Buffer.';
len_aux=length(Buffer);

Buffer=Buffer(Buffer~=0);%quita todos los 0 que sobren para ir en forma de FIFO con respecto al ultimo paquete agregado
len_aux2=length(Buffer);

len_aux_faltante=len_aux-len_aux2;%ceros faltantes

Buffer=[Buffer zeros(1,len_aux_faltante)];%transpuesta regresando la columna
Buffer=Buffer.';

end











