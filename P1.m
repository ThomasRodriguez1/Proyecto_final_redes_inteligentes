clear;
close all;
clc;

%Hola Thomas

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
lambda_index=2;

%duracion ranura
T=durDATA+durRTS+durCTS+DIFS+durACK+3*SIFS+sigma.*W(W_index);

%Ciclo de trabajo 
Tc = (2+Epsilon).*T;

tsim = 0.000000000000001; % tiempo de simulacion inicia en 0
ta=0; %valor para que ta sea menor a tsim al inicio del n ciclos


%inicializcion de buffers y contador paquetes
N_zeros=500000;
Buffer = zeros(K,N(N_index),I); %K,Nodos,Grados
Pkt=zeros(N_zeros,5);%cantidad de paquetes, susceptible a cambio en base a N_zeros



%variables contadoras
n_paquetes=0;

for t=1:10000*Tc

    if ta<tsim
        
        lambda_2=lambda(lambda_index)*N(N_index)*I;
        %nodo y grado aleatorio
        nodo_random=randsample(N(N_index),1);
        grado_random= randsample(I,1);
        %Variable AUX que obtiene los paquetes del buffer del nodo
        %aleatorio
        Aux=Buffer(:,nodo_random,grado_random);
        
        [ta ,n_paquetes,Aux,Pkt_aux]=arribo(ta,tsim,lambda_2,n_paquetes,Aux,nodo_random,grado_random);%funcion para generar arribo y paquete
        Buffer(:,nodo_random,grado_random)=Aux;
        Pkt(n_paquetes,:)=Pkt_aux;
    end
    
%     if mod(t, Tc) == 0 
%         for i=I:-1:1 %grado mas alto a mas bajo
%             for k=1:N(N_index)
%                 
%                 backoff()
%             end
%         end
%     end

    
    tsim = tsim + Tc;
end






%Generacion de nuevo paquete y asignacion al buffer
function [ta,n_paquetes,Aux,Pkt_aux]=arribo(ta,tsim,lambda_2,n_paquetes,Aux,nodo_random,grado_random)

Pkt_aux=zeros(1,5);
U = (1e6*rand())/1e6; 
%generacion de tiempo aleatorio
nuevot = -(1/lambda_2)*log(1-U);

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


%asignacion de valor nuevo a ta

ta = tsim + nuevot; 

end

function [Aux]=FIFO_buffer(Buffer)

Aux=Buffer.';%transpuesta por estar en forma de columna
len_aux=length(Aux);

Aux=Aux(Aux~=0);%quita todos los 0 que sobren para ir en forma de FIFO con respecto al ultimo paquete agregado
len_aux2=length(Aux);

len_aux_faltante=len_aux-len_aux2;%ceros faltantes

Aux=[Aux zeros(1,len_aux_faltante)].';%transpuesta regresando la columna

end







