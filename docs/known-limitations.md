# ⚠️ Limitaciones Conocidas y Deuda Técnica Documentada

**Proyecto:** Guagua ERP Comercial Venezuela  
**Fecha:** 12 de Octubre de 2026

---

1. **Régimen de Emisión Fiscal SENIAT No Homologado:**
   - El sistema no cuenta con homologación de imprenta digital ni conexión directa a impresoras fiscales seriales/fiscalizadores de memoria de auditoría SENIAT.
   - Todos los tickets emitidos son clasificados como **Documentos No Fiscales / Notas de Entrega Internas**.

2. **Falta de Contabilidad Formal (Libro Diario, Mayor y Estados Financieros):**
   - El sistema actual realiza contabilidad administrativa y de flujo de caja (ventas, compras, margen bruto estimado, cuentas por cobrar).
   - No implementa asientos de partida doble, catálogo de cuentas contables ni balance general formal.

3. **Multi-Empresa en Fase de Migración:**
   - La base de datos histórica contenía datos sin `company_id`. Se ha inicializado una empresa por defecto (`Guagua Enterprise C.A.`) para asociar los datos existentes.

4. **Soporte de Concurrencia en Modo Offline:**
   - Cuando múltiples terminales operan offline simultáneamente, las ventas locales se ordenan por marca de tiempo (`created_at`). Si dos cajeros venden la última unidad mientras están desconectados, el stock resultante en el servidor requerirá un ajuste de inventario al sincronizar.
