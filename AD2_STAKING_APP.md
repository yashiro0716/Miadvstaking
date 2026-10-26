# Integración de ADV2.0 Staking en la Mini App

La nueva pantalla está en `/staking`; la pantalla existente de ADV Rewards no se reemplaza.

## Variables públicas de configuración
Configurar en Vercel solo después de desplegar y verificar los contratos:
- `NEXT_PUBLIC_CHAIN_ID=480`
- `NEXT_PUBLIC_AD2_TOKEN=<dirección verificada del contrato ADV2.0>`
- `NEXT_PUBLIC_AD2_STAKING_CONTRACT=<dirección verificada del contrato AD2Staking>`

No introducir claves privadas, frases semilla ni credenciales en variables públicas.

## Flujo de uso
1. Conectar una billetera compatible con World Chain.
2. Verificar que la red sea World Chain Mainnet (480).
3. Consultar saldo AD2, principal depositado, recompensas pendientes y reserva disponible.
4. Para depositar, aprobar AD2 al contrato de staking y luego confirmar el depósito.
5. Retirar principal o reclamar recompensas con transacciones separadas.

## Bloqueos de seguridad
- Las operaciones de staking se desactivan automáticamente si no hay direcciones válidas configuradas.
- La pantalla no crea ni despliega contratos.
- No activar producción hasta comprobar la dirección y los decimales del token, ejecutar todos los tests, financiar una reserva de recompensas y completar una revisión de seguridad independiente.
- El APR de 20% es una regla fija del contrato de ejemplo, no una promesa de rentabilidad ni una garantía de solvencia.
- La app debe probarse primero en un entorno de pruebas. No se ha verificado aún el flujo transaccional dentro de World App en dispositivo real.
