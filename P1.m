clear all;
close all;
clc;

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
lambda = [ 0.0005, 0 .005, 0.03 ] ; % Tasa de generacion de paquetes por segundo


%indices de valores de miniranuras, N°de nodos por grado y del valor de lambda
W_index=1;
N_index=3;
lambda_index=1;

%duracion ranura
T=durDATA+durRTS+durCTS+DIFS+durACK+3*SIFS+sigma.*W(W_index);

%Ciclo de trabajo 
Tc = (2+Epsilon).*T;

tsim = 0; % tiempo de simulacion inicia en 0
ta=-1; %valor para que ta sea menor a tsim al inicio del n ciclos


%inicializcion de buffers
Buffer = zeros(N(N_index),K,I); 

%variables contadoras
n_paquetes=0;

for t=1:2*Tc

    if ta<tsim
        
        lambda_2=lambda(1)*N(N_index)*I;
        [ta ,n_paquetes,Buffer]=arribo(tsim,lambda_2,N,N_index,I,n_paquetes,Buffer);
        %falta guardar el nuevo paquete en el buffer
    end


end

%generacion de nuevo paquete y asignacion al buffer
function [ta,n_paquetes,Buffer]=arribo(tsim,lambda_2,N,N_index,I,n_paquetes,Buffer)

U = (1e6*rand())/1e6; 
%generacion de tiempo aleatorio
nuevot = -(1/lambda_2)*log(1-U);
%nodo y grado aleatorio
nodo_random=randsample(N(N_index),1);
display(nodo_random)
grado_random= randsample(I,1);
display(grado_random)

%generacion y asignacion de paquetes

n_paquetes=n_paquetes+1;

%asignacion de valor nuevo a ta
ta = tsim + nuevot; 

end








