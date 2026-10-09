# Reglas del Proyecto (Fina / Guagua POS)

## 🛡️ Principios de Calidad, Limpieza y Estabilidad

1. **Cero Código Inservible (Zero Dead Code):**
   - No dejar código muerto, funciones en desuso, variables no utilizadas, archivos temporales ni bloques de código comentados.
   - Si una refactorización reemplaza una función o componente antiguo, eliminar el código anterior completamente.

2. **Cero Bugs & 100% Responsivo Obligatorio (Visual y Funcional):**
   - **REGLA OBLIGATORIA:** Cada modificación, componente, pantalla o funcionalidad creada DEBE SER 100% RESPONSIVA Y ADAPTATIVA para cualquier dispositivo, ya sea Teléfono Móvil (Android/iOS), Tablet, PC de Escritorio (Windows) o Web.
   - **Cero Pixel Overflow:** Verificar siempre que no existan desbordamientos de pantalla (`RenderFlex overflowed by X pixels`), errores de tipo en runtime ni fallos en la lógica de datos.
   - Aplicar estrictamente las normas de las skills `flutter-responsive-adaptive` y `flutter-responsive-adaptive-design` (`FittedBox` para montos numéricos, `Expanded`/`Flexible` con `TextOverflow.ellipsis` para textos en `Row`, `Wrap` para cabeceras y `LayoutBuilder` / `ResponsiveLayout` para grillas y navegación adaptativa en Mobile `<600px`, Tablet `600-1024px` y Desktop `>1024px`).

3. **Verificación Estricta antes de Entregar:**
   - Ejecutar análisis estático (`flutter analyze`), tests (`flutter test`) y la checklist de `flutter-ui-states-ux` tras modificar archivos para garantizar que el proyecto compila sin advertencias ni errores.

4. **Refactorización Atómica:**
   - Si se modifica una firma de función, modelo de datos o componente de interfaz, actualizar **todos** los puntos de invocación en la aplicación simultáneamente para preservar la integridad global.

5. **🚀 Protocolo Obligatorio Pre-Push / Commits:**
   - **NUNCA** hacer un `git push` o entrega final sin ejecutar antes una **prueba completa del sistema**.
   - Validar que:
     - El proyecto compila limpiamente sin errores de análisis (`flutter analyze`).
     - Todas las pantallas renderizan sin errores visuales ni desbordamientos en resoluciones móvil y PC.
     - Las integraciones de base de datos, flujos de autenticación y transacciones POS respondan correctamente.

6. **CERO DATOS INVENTADOS (Strict NO MOCK DATA Rule):**
   - **REGLA ABSOLUTA:** Ninguna pantalla, módulo o componente (Dashboard, Inventario, Crédito, POS) debe contener listas estáticas (ej. `_inventory = [...]`), valores duros ni "mock data".
   - Toda información, métrica o lista debe provenir única y exclusivamente de la base de datos real en Supabase, ya sea devolviendo un arreglo vacío `[]` o `$0.00` si la base de datos está vacía.
   - Si se requiere construir la UI, se hace asumiendo que los datos vendrán de Supabase o se deja el estado vacío, pero JAMÁS se entregan listas "falsas" al usuario final.

7. **Uso Obligatorio de las Skills Guagua POS:**
   Antes de tocar UI o lógica, consultar y aplicar SIEMPRE estas skills esenciales:
   - `flutter-pos-design-system`
   - `flutter-responsive-adaptive`
   - `flutter-pos-business-logic`
   - `flutter-ui-states-ux`
   - `flutter-pos-architecture`
   - `fina-architecture`
   - `flutter-supabase-dev`

