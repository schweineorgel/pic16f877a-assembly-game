# PIC16F877A – Juego en Assembly

<img width="1920" height="1152" alt="image" src="https://github.com/user-attachments/assets/965c47ac-087e-4a00-a90f-186c2144714a" />

## Descripción
Juego desarrollado completamente en Assembly para el microcontrolador PIC16F877A.
El proyecto implementa lógica de juego en tiempo real, generación pseudoaleatoria de obstáculos,
detección de colisiones, sistema de niveles y control por interrupciones.

## Características
- Control del jugador mediante interrupciones por PORTB
- Obstáculos verticales y horizontales
- Generación pseudoaleatoria de huecos
- Sistema de vidas y puntaje
- Aumento progresivo de dificultad
- Renderizado mediante PORTC y PORTD

## Tecnologías
- Microcontrolador: PIC16F877A
- Lenguaje: Assembly (MPASM)
- Entorno: MPLAB / Simulación o hardware real

## Estructura
- `main.asm`: código fuente completo del juego

## Contexto
Proyecto desarrollado con fines académicos y de portafolio,
enfocado en demostrar manejo de bajo nivel, control de hardware
y diseño de sistemas embebidos.

## Simulación (SimulIDE)

El proyecto incluye un archivo de simulación para SimulIDE que permite
visualizar y probar el juego en un entorno virtual con el PIC16F877A.

Ruta: simulide/WallDash.sim1

Requisitos:
- SimulIDE (https://simulide.com)

Abrir el archivo `.sim1` directamente desde SimulIDE.

## Licencia
MIT License
