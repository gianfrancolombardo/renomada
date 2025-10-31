-- ==============================================
-- QUERY ÚNICA PARA REVISAR TODAS LAS POLÍTICAS RLS
-- ==============================================

-- Esta query te da toda la información necesaria para entender cada política
WITH all_policies AS (
    -- Políticas de tablas públicas
    SELECT 
        'public' as schema_type,
        schemaname,
        tablename,
        policyname,
        permissive,
        CASE 
            WHEN roles IS NULL THEN 'PUBLICO (riesgo)'
            ELSE ARRAY_TO_STRING(roles, ', ')
        END as roles_info,
        cmd as operation,
        CASE 
            WHEN cmd = 'SELECT' THEN '🔍 LECTURA'
            WHEN cmd = 'INSERT' THEN '➕ INSERTAR'
            WHEN cmd = 'UPDATE' THEN '✏️ ACTUALIZAR'
            WHEN cmd = 'DELETE' THEN '🗑️ ELIMINAR'
            WHEN cmd = 'ALL' THEN '🔄 TODAS LAS OPERACIONES'
            ELSE cmd
        END as operation_desc,
        qual as condition_using,
        with_check as condition_with_check,
        CASE 
            WHEN qual IS NULL AND with_check IS NULL THEN '❌ SIN RESTRICCIONES (peligroso)'
            WHEN qual IS NOT NULL AND with_check IS NULL THEN '✅ RESTRICCIÓN EN USANDO'
            WHEN qual IS NULL AND with_check IS NOT NULL THEN '✅ RESTRICCIÓN EN VERIFICACIÓN'
            ELSE '✅ RESTRICCIÓN EN AMBAS'
        END as security_level,
        CASE 
            WHEN roles IS NULL OR 'public' = ANY(roles) OR 'anon' = ANY(roles) THEN '⚠️ ACCESO PÚBLICO'
            ELSE '🔒 ACCESO RESTRINGIDO'
        END as access_type
    FROM pg_policies 
    WHERE schemaname = 'public'
    
    UNION ALL
    
    -- Políticas de storage (buckets)
    SELECT 
        'storage' as schema_type,
        schemaname,
        tablename as bucket_name,
        policyname,
        permissive,
        CASE 
            WHEN roles IS NULL THEN 'PUBLICO (riesgo)'
            ELSE ARRAY_TO_STRING(roles, ', ')
        END as roles_info,
        cmd as operation,
        CASE 
            WHEN cmd = 'SELECT' THEN '🔍 DESCARGAR'
            WHEN cmd = 'INSERT' THEN '➕ SUBIR'
            WHEN cmd = 'UPDATE' THEN '✏️ MODIFICAR'
            WHEN cmd = 'DELETE' THEN '🗑️ ELIMINAR'
            WHEN cmd = 'ALL' THEN '🔄 TODAS LAS OPERACIONES'
            ELSE cmd
        END as operation_desc,
        qual as condition_using,
        with_check as condition_with_check,
        CASE 
            WHEN qual IS NULL AND with_check IS NULL THEN '❌ SIN RESTRICCIONES (peligroso)'
            WHEN qual IS NOT NULL AND with_check IS NULL THEN '✅ RESTRICCIÓN EN USANDO'
            WHEN qual IS NULL AND with_check IS NOT NULL THEN '✅ RESTRICCIÓN EN VERIFICACIÓN'
            ELSE '✅ RESTRICCIÓN EN AMBAS'
        END as security_level,
        CASE 
            WHEN roles IS NULL OR 'public' = ANY(roles) OR 'anon' = ANY(roles) THEN '⚠️ ACCESO PÚBLICO'
            ELSE '🔒 ACCESO RESTRINGIDO'
        END as access_type
    FROM pg_policies 
    WHERE schemaname = 'storage'
)

SELECT 
    schema_type as "TIPO",
    tablename as "TABLA/BUCKET",
    policyname as "POLÍTICA",
    operation_desc as "OPERACIÓN",
    roles_info as "ROLES PERMITIDOS",
    access_type as "TIPO DE ACCESO",
    security_level as "NIVEL DE SEGURIDAD",
    COALESCE(condition_using, 'Sin condición USING') as "CONDICIÓN USING",
    COALESCE(condition_with_check, 'Sin condición WITH CHECK') as "CONDICIÓN WITH CHECK"
FROM all_policies
ORDER BY 
    CASE schema_type WHEN 'public' THEN 1 WHEN 'storage' THEN 2 END,
    tablename,
    operation;
