clear;
close all;
clc;

tic %inicia contador, acaba en toc

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
W_index=1;
N_index=2;
lambda_index=3;

%duracion ranura
T = (sigma.*W(W_index))+ DIFS + 3*SIFS + durRTS+ durCTS+ durDATA + durACK; %%6000 ciclos
%T=durDATA+durRTS+durCTS+DIFS+durACK+(sigma.*W(W_index))+(3*SIFS); %2600 ciclos aprox

%Ciclo de trabajo 
Tc = (2+Epsilon).*T;

tsim = 0.000000000000001; % tiempo de simulacion inicia en 0
ta=0; %valor para que ta sea menor a tsim al inicio del n ciclos


%inicializcion de buffers y contador paquetes
N_zeros=300000000; %tamaño array general del buffer y de otros
Buffer = zeros(K,N(N_index),I); %K,Nodos,Grados
Pkt=zeros(N_zeros,6);%cantidad de paquetes, susceptible a cambio en base a N_zeros [n_paquete,nodo,grado,ta,estado,tiempo_total]
backoff=zeros(N(N_index),I);%Array para los contendientes de paquetes a enviar



%variables contadoras
n_ciclos=0;
n_paquetes=0;
n_colisiones=0;
n_paquetes_sink=0;%paquetes que llegaron al nodo sink
Throughput=zeros(1,I);%Paquetes exitosos por grado

%arrays para guardar las estadisticas de los paquetes 
a_colisiones = zeros(1,7);
aux_buffer_ = 0;

%arrays para guardar las estadisticas de los paquetes cuando el buffer este lleno 
a_buffer_lleno=zeros(1,7);


%iniciamos asignando nodo a grado
lambda_2=lambda(lambda_index)*N(N_index)*I;
nodo_random=randi(N(N_index),1);
grado_random= randi([2 I],1) ;
U = (1e6*rand())/1e6; 
nuevot = -(1/lambda_2)*log(1-U);
ta=tsim+nuevot;

for t=1:300000

    while ta<tsim
        if Buffer(15,nodo_random,grado_random)==0
            Aux=Buffer(:,nodo_random,grado_random);  %Variable AUX que obtiene los paquetes del del nodo aleatorio
            [n_paquetes,Aux,Pkt_aux]=arribo(ta,n_paquetes,Aux,nodo_random,grado_random);%funcion para generar arribo y paquete
            Buffer(:,nodo_random,grado_random)=Aux;
            Pkt(n_paquetes,:)=Pkt_aux;
        else
            for e=1:I
                if e==grado_random
                    a_buffer_lleno(e)=a_buffer_lleno(e)+1;%Aumenta contador de paquetes perdidos por buffer lleno
                end
            end
        end
        
        %generacion de tiempo aleatorio
        U = (1e6*rand())/1e6; 
        nuevot = -(1/lambda_2)*log(1-U);
        ta=tsim+nuevot;
        
        %nodo y grado aleatorio
        nodo_random=randi(N(N_index),1);
        grado_random= randi([2 I],1) ;
      
    end
    
    
        n_ciclos=n_ciclos+1;
        %GENERADOR DE BACKOFF
        for grado=I:-1:1 %grado mas alto a mas bajo
            for nodo=1:N(N_index)
               if Buffer(1,nodo,grado)~=0 %Si el paquete en 1 es diferente de 0 tiene un paquete por enviar
                   backoff(nodo,grado)=randi(W(W_index),1);
               else
                   backoff(nodo,grado)=W(W_index)+1; %%Nunca se llegara a este valor, por lo cual se llena cuando no hay paquete que enviar o en el buffer  
               end
            end
            %Escoger backoff minimo del grado I
            backoff_min=min(backoff(:,grado));
            
            if backoff_min~=(W(W_index)+1)%%Indica que el valor minimo no es al que no se deberia de llegar
             
                Colision=find(backoff(:,grado)==backoff_min);%Crear array con los valores que encuentra que tengan el mismo backoff
                len_colision=length(Colision);%longitud de datos en array Colision
                
                if len_colision<=1  %Si hay mas de un valor, quiere decir que hay colision
                    Aux_n_pkt=Buffer(1,Colision(1),grado);%tomamos numero del primer paquete del nodo
                    Buffer(1,Colision(1),grado)=0;%Colocamos primer paquete en 0, que indica que esta vacio
                    Buffer(:,Colision(1),grado)=FIFO_buffer(Buffer(:,nodo_random,grado_random));
                    
                    if grado~=1 %nodo Sink, por lo tanto no hay porque agregar mas paquetes a otros nodos 
                        if grado-1~=1
                            if Buffer(15,Colision(1),grado-1)==0  %que la cola del buffer tenga espacio para otro paquete
                                Buffer(15,Colision(1),grado-1)=Aux_n_pkt;%se le asigna el numero del paquete tomado anteriormente
                                Buffer(:,Colision(1),grado-1)=FIFO_buffer(Buffer(:,Colision(1),grado-1));
                                Throughput(grado)=Throughput(grado)+1;
                            else
                                %Verificacion buffer lleno  %1 exitoso 2=Colision 3=Buffer lleno
                                Pkt(Aux_n_pkt,5)=3;

                                %asignamos a cada grado, el numero de paquetes que encontraron el buffer lleno
                                for e=1:I
                                    if e==grado
                                        a_buffer_lleno(e)=a_buffer_lleno(e)+1;%Aumenta contador de paquetes perdidos por buffer lleno
                                    end
                                end
                            end
                        else
                            Throughput(grado)=Throughput(grado)+1;
                        end
                        
                    else %cuando grado=1
                        Pkt(Aux_n_pkt,6)=tsim;%indica el tiempo que tomo para que este lograra llegar al nodo sink
                        n_paquetes_sink=n_paquetes_sink+1;
                        Throughput(grado)=Throughput(grado)+1;
                    end
                else
                    for col=1:len_colision
                        n_colisiones=n_colisiones+1;
                        
                        %asignamos a cada grado, el numero de paquetes que
                        %colicionan en el
                        for e=1:I
                            if e==grado
                                a_colisiones(e)=a_colisiones(e)+1;%Aumenta contador de paquetes colisionados
                            end
                        end
                        aux_index=Colision(col);%toma el valor del indice del buffer(nodo) en array colisiones
                        aux_colision=Buffer(1,aux_index,grado);
                        Pkt(aux_colision,5)=2; %colocamos estado "2" de colision con otros paquetes
                        Buffer(1,aux_index,grado)=0;
                        Buffer(:,aux_index,grado)=FIFO_buffer(Buffer(:,aux_index,grado));
                    end
                end
            end
        end 
    

    %backoff=zeros(I,N(N_index));%Reiniciar conteo de los backoff
    tsim = tsim + Tc;
%     if n_ciclos==300000 %Llega a 300k ciclos y se rompe
%       break
%     end
end


%%impresion de estadisticas

%grafica de coliciones por grado
figure()
stem(a_colisiones, 'LineWidth',2)
xlim([0 8])
title('Paquetes colisionados')
ylabel('# paquetes colisionados')
xlabel('Grado')
grid on

%paquetes exitosos
figure()
stem( Throughput, 'LineWidth',2)
xlim([0 8])
title('Throughput')
ylabel('Paquetes transmitidos exitosamente')
xlabel('Grado')
grid on

%grafica de los paquetes que encontaron el buffer lleno por grado
figure()
stem(a_buffer_lleno, 'LineWidth',2)
xlim([0 8])
title('Paquetes que encontraron el buffer lleno')
ylabel('# paquetes sin Tx')
xlabel('Grado')
grid on

figure()
stem(a_colisiones + a_buffer_lleno, 'LineWidth',2)
xlim([0 8])
title('Paquetes perdidos por grado')
ylabel('# paquetes perdidos')
xlabel('Grado')
grid on

toc %acaba contador







%Generacion de nuevo paquete y asignacion al buffer
function [n_paquetes,Aux,Pkt_aux]=arribo(ta,n_paquetes,Aux,nodo_random,grado_random)

Pkt_aux=zeros(1,6);

%generacion y asignacion de paquetes

n_paquetes=n_paquetes+1;

Pkt_aux(1) = n_paquetes;
Pkt_aux(2) = nodo_random;
Pkt_aux(3) = grado_random;
Pkt_aux(4) = ta;
%Verificacion buffer lleno  %1 exitoso 2=Colision 3=Buffer lleno

if Aux(15)==0
    
        Aux(15)=n_paquetes;
        Aux=FIFO_buffer(Aux);%Funcion para recorrer el buffer 
else
 
        Pkt_aux(5)=3;
                        
end

end

%%moviendo paquetes recien ingresados del buffer(15) al buffer mas cercano
%%al inicio que no este ocupado
function [Aux]=FIFO_buffer(Buffer)

Aux=Buffer.';%transpuesta por estar en forma de columna
len_aux=length(Aux);

Aux=Aux(Aux~=0);%quita todos los 0 que sobren para ir en forma de FIFO con respecto al ultimo paquete agregado
len_aux2=length(Aux);

len_aux_faltante=len_aux-len_aux2;%ceros faltantes

Aux=[Aux zeros(1,len_aux_faltante)].';%transpuesta regresando la columna

end







