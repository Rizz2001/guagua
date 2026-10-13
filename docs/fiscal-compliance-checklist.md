# 📋 Checklist de Cumplimiento Fiscal Venezolano (SENIAT)

**Estado:** 🔒 PUERTA DE CONTROL ACTIVA (Emisión fiscal formal bloqueada hasta validación legal)

| # | Requisito / Obligación Fiscal | Norma / Providencia | Estado en Sistema | Acción Requerida |
| :-: | :--- | :--- | :---: | :--- |
| **1** | Identificación del Emisor (RIF, Razón Social, Domicilio Fiscal) | Providencia SNAT/2011/00071 Art. 13 | 🟢 Configurado | Parametrizado en la entidad `companies`. |
| **2** | Identificación del Adquiriente (Nombre/Razón Social, RIF/Cédula) | Providencia SNAT/2011/00071 Art. 13 | 🟢 Implementado | Capturado en módulo `clients` y ventas. |
| **3** | Numeración Consecutiva y Única de Factura | Providencia SNAT/2011/00071 Art. 14 | 🟡 Parcial | Actualmente generado como UUID/correlativo interno; requiere tabla `document_sequences` con bloqueo atómico. |
| **4** | Número de Control Fiscal | Providencia SNAT/2011/00071 Art. 24 | 🔴 Bloqueado | Requiere formas libres autorizadas o imprenta digital homologada. |
| **5** | Desglose de Alícuota General de IVA (16%), Reducida (8%) y Exento | Ley de IVA Arts. 18, 27 | 🟡 Parcial | Catálogo de productos requiere campo `tax_code` / `tax_rate`. |
| **6** | Impuesto a las Grandes Transacciones Financieras (IGTF 3%) | Ley de IGTF / Reforma 2022 | 🟢 Implementado | Calculado exactamente sobre pagos en divisas / Zelle. |
| **7** | Tasa Oficial de Cambio (BCV del día) | Convenio Cambiario N° 1 | 🟢 Implementado | Gestión diaria manual con congelación en el ticket de venta. |
| **8** | Declaración de "Documento No Fiscal" en tickets internos | Normativa de control interno | 🟢 Implementado | Encabezado claro: *"DOCUMENTO INTERNO NO FISCAL"*. |
