# AlgoritmoABC_ClasificadorDeIntenciónMotora

El siguiente repositorio incluye los archivos necesarios para ejecutar las diferentes 
etapas del proyecto

"Desarrollo y validación de un algoritmo para la clasificación de 
patrones de movimiento en las extremidades superiores en señales de electroencefalograma 
mediante el uso de una red neuronal supervisada"

Nota: Para ejecutar los codigos de la carpeta Matlab, añadir los archivos del siguiente link en el Path de Matlab:
https://drive.google.com/drive/folders/1fs2B0Z40hT1bYfQzl6EoIZevgL7HBxbq?usp=share_link

El orden para ejecutarse es el siguiente:
1. AlgoritmoABC_Python -> LeerOpenBCI.py
2. Previo a ejecutar los codigos de Matlab se debe añadir al Path la carpeta eeglab2022.1 con sus subcarpetas
3. AlgoritmoABC_Matlab -> Ejecutar archivos PreprocesadoABC_Perceptron.m y PreprocesadoABC_Conv.m
5. AlgoritmoABC_Matlab -> Ejecutar archivos AlgoritmoABC_Perceptron.m, AlgoritmoABC_Perceptron_BT.m y AlgoritmoABC_CNN.m
6. AlgoritmoABC_Matlab -> Ejecutar archivo GUI_Algoritmo_ABC_CNN.m
7. AlgoritmoABC_Tensorflow -> Ejecutar archivos ABC_Perceptron_Scaled.ipynb y ABC_CNN.ipynb añadiendo previamente los archivos necesarios para el entrenamiento

Versión de Matlab: R2020b
