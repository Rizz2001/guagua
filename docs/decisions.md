# 📝 Registro de Decisiones de Arquitectura (ADR)

**Proyecto:** Guagua ERP Comercial Venezuela

---

### ADR-001: Esquema Multi-Tenant con `company_id` Compartido y RLS Estricto
- **Contexto:** El sistema requería soportar múltiples empresas manteniendo una única base de datos PostgreSQL en Supabase.
- **Decisión:** Usar una arquitectura de base de datos compartida (*Shared Database, Shared Schema*) con una columna obligatoria `company_id` en todas las entidades comerciales y políticas Row-Level Security (RLS) evaluadas dinámicamente mediante `auth.uid()`.
- **Consecuencias:** Aislamiento 100% garantizado a nivel de base de datos sin requerir múltiples proyectos de Supabase ni esquemas dinámicos complejos.

---

### ADR-002: Transacciones Atómicas Vía RPC para Operaciones Financieras Críticas
- **Contexto:** En la versión anterior de POS, `OutboxService` realizaba inserts secuenciales en `sales` y luego en `sale_items`, arriesgando registros huérfanos si la conexión fallaba a mitad del proceso.
- **Decisión:** Reemplazar llamadas secuenciales por funciones RPC en PostgreSQL (`SECURITY DEFINER`) con transacciones ACID completas y clave de idempotencia (`idempotency_key`).
- **Consecuencias:** Integridad absoluta en la base de datos; las ventas se insertan completamente o se revierten sin dejar datos corruptos.

---

### ADR-003: Tratamiento de Documentos Fiscales vs Documentos Comerciales Internos
- **Contexto:** La normativa venezolana (SENIAT) exige cumplimiento riguroso de medios de emisión (máquinas fiscales, formas libres o imprentas digitales autorizadas).
- **Decisión:** Hasta contar con la homologación y revisión de un asesor tributario colegiado, todos los comprobantes emitidos por el sistema se denominarán explícitamente **"Documento No Fiscal / Comanda Interna"**.
- **Consecuencias:** Se elimina el riesgo legal de falsas declaraciones de cumplimiento y se permite a los comercios operar ventas internas mientras se valida el régimen de emisión fiscal.
