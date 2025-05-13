-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 04-05-2025 a las 18:29:30
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `u415516518_agenda_mujeres`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `ActualizarEstadoPagoPorCedula` (IN `cedulaProfesor` VARCHAR(20))   BEGIN
    DECLARE profesorID INT;
    DECLARE mensaje VARCHAR(255);
    DECLARE codigo INT;

    -- Obtener el ID del profesor a partir de la c├®dula
    SELECT ID INTO profesorID
    FROM profesores
    WHERE Cedula = cedulaProfesor;

    -- Verificar si se encontr├│ el profesor
    IF profesorID IS NOT NULL THEN
        -- Actualizar el EstadoPago para los registros relacionados con el profesor
        UPDATE estadopagoprofesor
        SET EstadoPago = 1
        WHERE idProfesor = profesorID;
        
        -- Comprobar si se realizaron actualizaciones
        IF ROW_COUNT() > 0 THEN
            SET mensaje = 'Pagos Actualizados de manera exitosa';
            SET codigo = 200; -- C├│digo de ├®xito
        ELSE
            SET mensaje = 'No se encontraron registros para actualizar';
            SET codigo = 404; -- No encontrado
        END IF;
    ELSE
        SET mensaje = 'No se encontr├│ un profesor con esa c├®dula';
        SET codigo = 404; -- No encontrado
    END IF;

    -- Retornar el mensaje y el c├│digo
    SELECT codigo AS codigo, mensaje AS mensaje;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DetallesPagoCurso` (IN `p_IdCurso` INT)   BEGIN
    SELECT 
        m.Id ,
        c.NombreCurso,
        m.Nombre  ,
        m.Cedula  ,
        m.Telefono  ,
        m.Correo ,
        ROUND(c.Precio * (c.PorcentajePagoProfe / 100), 2) AS 'Monto' -- Monto a cancelar con dos decimales
    FROM 
        matriculas m
    JOIN 
        cursos c ON m.IdCurso = c.ID
    WHERE 
        c.ID = p_IdCurso -- Usar el par├ímetro recibido
        AND m.estadoPago = 'Pagado'
        AND m.desercion = 0;-- Puedes cambiar esta condici├│n seg├║n tu necesidad
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarProfesor` (IN `profesorID` INT)   BEGIN
    -- Verificar si el profesor est├í asignado en la tabla horarios_cursos
    DECLARE existeEnHorarios INT;

    -- Contar cu├íntas veces aparece el ID del profesor en la tabla horarios_cursos
    SELECT COUNT(*) INTO existeEnHorarios
    FROM horarios_cursos
    WHERE idProfesor = profesorID;

    -- Si no est├í asignado en horarios_cursos, proceder con la eliminaci├│n
    IF existeEnHorarios = 0 THEN
        DELETE FROM profesores WHERE ID = profesorID;
        -- Retornar c├│digo 0 y mensaje de ├®xito
        SELECT 0 AS codigo, 'Profesor eliminado correctamente' AS mensaje;
    ELSE
        -- Si est├í asignado en horarios_cursos, devolver un c├│digo -1 y mensaje
        SELECT -1 AS codigo, 'No se puede eliminar el profesor porque est├í asignado a horarios de cursos' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarMovimientoPagoProfesor` (IN `p_tipoMovimiento` TINYINT, IN `p_monto` DECIMAL(10,2), IN `p_idCurso` INT, IN `p_idProfesor` INT, IN `p_Notas` TEXT, IN `p_comprobante` VARCHAR(100), IN `p_fecha` DATETIME, IN `p_calculoPago` INT)   BEGIN
    INSERT INTO movimientosdineroProfesores (tipoMovimiento, monto, idCurso, idProfesor, Notas, comprobante, fecha)
    VALUES (p_tipoMovimiento, p_monto, p_idCurso, p_idProfesor, p_Notas, p_comprobante, p_fecha);
	
    delete from listapagosprofesor where idPago =  p_calculoPago;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarMovimientoPorMatriculaPagoCliente` (IN `p_IdMatricula` INT, IN `p_Cuota` DECIMAL(10,2), IN `p_Notas` VARCHAR(255), IN `p_Comprobante` VARCHAR(255))   BEGIN
    DECLARE v_IdCurso INT;
    DECLARE v_NombreCurso VARCHAR(255);
    DECLARE v_CedulaClientePaga VARCHAR(50);
    DECLARE v_NombreClientePaga VARCHAR(255);
    DECLARE v_TelefonoClientePaga VARCHAR(20);
    DECLARE v_EmailClientePaga VARCHAR(255);
    DECLARE v_Comprobante VARCHAR(255);

    -- Actualizar el comprobante en la tabla matriculas
    UPDATE matriculas
    SET comprobante = p_Comprobante
    WHERE Id = p_IdMatricula;

    -- Obtener los datos necesarios de las tablas matriculas y cursos
    SELECT 
        m.IdCurso,
        c.NombreCurso,
        m.Cedula,
        m.Nombre,
        m.Telefono,
        m.Correo,
        m.comprobante
    INTO 
        v_IdCurso,
        v_NombreCurso,
        v_CedulaClientePaga,
        v_NombreClientePaga,
        v_TelefonoClientePaga,
        v_EmailClientePaga,
        v_Comprobante
    FROM 
        matriculas m
    JOIN 
        cursos c ON m.IdCurso = c.ID
    WHERE 
        m.Id = p_IdMatricula;
    
    -- Insertar el nuevo registro en la tabla movimientosdinero
    INSERT INTO movimientosdinero (
        tipoMovimiento,
        monto,
        idCurso,
        idMatricula,
        NombreCurso,
        Envia,
        Recibe,
        CedulaClientePaga,
        NombreClientePaga,
        TelefonoClientePaga,
        EmailClientePaga,
        Notas,
        comprobante,
        fecha
    ) VALUES (
        1,  -- Tipo de movimiento (puedes modificarlo si necesitas un par├ímetro)
        p_Cuota, 
        v_IdCurso,
        p_IdMatricula,
        v_NombreCurso,
        'CLIENTE',  -- Puedes ajustar seg├║n sea necesario
        'SISTEMA',  -- Recibe el nombre del cliente que paga
        v_CedulaClientePaga,
        v_NombreClientePaga,
        v_TelefonoClientePaga,
        v_EmailClientePaga,
        p_Notas,  -- Notas desde el par├ímetro
        p_Comprobante,  -- Comprobante desde el par├ímetro
        NOW()  -- Fecha actual
    );

    update matriculas set cuotasPendientes = cuotasPendientes - 1 where id = p_IdMatricula;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarMovimientoPorMatriculaPagoProfesor` (IN `p_IdCurso` INT, IN `p_Notas` VARCHAR(255), IN `p_Comprobante` VARCHAR(255))   BEGIN
    DECLARE v_IdMatricula INT;      -- Variable para almacenar el ID de matr├¡cula
    DECLARE v_NombreCurso VARCHAR(255);
    DECLARE v_CedulaClientePaga VARCHAR(50);
    DECLARE v_NombreClientePaga VARCHAR(255);
    DECLARE v_TelefonoClientePaga VARCHAR(20);
    DECLARE v_EmailClientePaga VARCHAR(255);
    DECLARE done INT DEFAULT FALSE;

    -- Declarar un cursor para obtener las matr├¡culas por ID de curso
    DECLARE cur CURSOR FOR 
    SELECT 
        m.Id,
        c.NombreCurso,
        m.Cedula,
        m.Nombre,
        m.Telefono,
        m.Correo
    FROM 
        matriculas m
    JOIN 
        cursos c ON m.IdCurso = c.ID
    WHERE 
        m.IdCurso = p_IdCurso;

    -- Manejar el fin del cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Abrir el cursor
    OPEN cur;

    -- Leer cada fila del cursor
    read_loop: LOOP
        FETCH cur INTO v_IdMatricula, v_NombreCurso, v_CedulaClientePaga, v_NombreClientePaga, v_TelefonoClientePaga, v_EmailClientePaga;
        
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Insertar el nuevo registro en la tabla movimientos
        INSERT INTO movimientosdinero (
            tipoMovimiento,
            monto,
            idCurso,
            idMatricula,
            NombreCurso,
            Envia,
            Recibe,
            CedulaClientePaga,
            NombreClientePaga,
            TelefonoClientePaga,
            EmailClientePaga,
            Notas,
            comprobante,
            fecha
        ) VALUES (
            2,  -- Tipo de movimiento
            ROUND((SELECT Precio * (PorcentajePagoProfe / 100) FROM cursos WHERE ID = p_IdCurso), 2), -- Monto calculado
            p_IdCurso,
            v_IdMatricula,
            v_NombreCurso,
            'SISTEMA',  -- Puedes ajustar seg├║n sea necesario
            'PROFESOR',  -- Recibe el nombre del cliente que paga
            v_CedulaClientePaga,
            v_NombreClientePaga,
            v_TelefonoClientePaga,
            v_EmailClientePaga,
            p_Notas,  -- Notas desde el par├ímetro
            p_Comprobante,  -- Comprobante desde el par├ímetro
            NOW()  -- Fecha actual
        );

        -- Actualizar el estado de pago en la tabla estadopagoprofesor
        UPDATE estadopagoprofesor
        SET EstadoPago = 1  -- O el estado que necesites
        WHERE IdMatricula = v_IdMatricula;  -- Solo se utiliza IdMatricula

    END LOOP;

    -- Cerrar el cursor
    CLOSE cur;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertarPagosProfesores` ()   BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_NombreProfesor VARCHAR(255);
    DECLARE v_NombreCurso VARCHAR(255);
    DECLARE v_idProfesor INT;
    DECLARE v_idCurso INT;
    DECLARE v_CedulaProfesor VARCHAR(50);
    DECLARE v_TelefonoProfesor VARCHAR(50);
    DECLARE v_CorreoProfesor VARCHAR(255);
    DECLARE v_TotalPagar DECIMAL(10,2);
    
    DECLARE cur CURSOR FOR
        SELECT p.NombreProfesor, c.NombreCurso, h.IdProfesor, c.ID, p.Cedula, p.Telefono, p.Correo, 
               SUM(m.monto * c.PorcentajePagoProfe / 100) AS TotalPagar
        FROM movimientosdinero m
        INNER JOIN horarios_cursos h ON m.idCurso = h.IdCurso
        INNER JOIN cursos c ON h.IdCurso = c.ID
        INNER JOIN profesores p ON h.IdProfesor = p.ID
        WHERE m.sePagoPorcentaje = 0
        GROUP BY p.ID, c.ID, p.NombreProfesor, c.NombreCurso, p.Cedula, p.Telefono, p.Correo;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_NombreProfesor, v_NombreCurso, v_idProfesor, v_idCurso, v_CedulaProfesor, v_TelefonoProfesor, v_CorreoProfesor, v_TotalPagar;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si ya existe un registro en listapagosprofesor
        IF NOT EXISTS (
            SELECT 1 FROM listapagosprofesor 
            WHERE idProfesor = v_idProfesor AND idCurso = v_idCurso
        ) THEN
            -- Insertar en listapagosprofesor
            INSERT INTO listapagosprofesor (NombreProfesor, NombreCurso, idProfesor, idCurso, CedulaProfesor, TelefonoProfesor, CorreoProfesor, TotalPagar, EstadoPago)
            VALUES (v_NombreProfesor, v_NombreCurso, v_idProfesor, v_idCurso, v_CedulaProfesor, v_TelefonoProfesor, v_CorreoProfesor, v_TotalPagar, 0);
        END IF;
    END LOOP;
    
    CLOSE cur;

    -- Actualizar todos los registros en movimientosdinero al final
    UPDATE movimientosdinero
    SET sePagoPorcentaje = 1
    WHERE id > 0;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerHorariosCurso` (IN `cursoID` INT)   BEGIN
    SELECT 
        h.ID AS `idHorario`,
        h.DiaSemana AS `D├¡a`,
        h.HoraInicio AS `HoraInicio`,
        h.HoraFin AS `HoraFin`,
        p.NombreProfesor AS `Profesor`,
        h.Cupo AS `CupoInicial`,  -- Tomando el cupo de la tabla horarios_cursos
        (h.Cupo - COUNT(m.IdCurso)) AS `CupoRestante`  -- C├ílculo de cupo restante basado en la combinaci├│n de horario y curso
    FROM 
        horarios_cursos h
    INNER JOIN 
        cursos c ON h.IdCurso = c.ID  -- Relacionar horarios con cursos
    INNER JOIN 
        profesores p ON h.IdProfesor = p.ID  -- Relacionar horarios con profesores
    LEFT JOIN 
        matriculas m ON m.IdCurso = c.ID 
        AND m.IdHorario = h.ID  -- Relacionar correctamente las matriculas con el curso y el horario
    WHERE 
        c.ID = cursoID  -- Filtrar por el ID del curso proporcionado
    GROUP BY 
        h.ID, h.DiaSemana, h.HoraInicio, h.HoraFin, p.NombreProfesor, h.Cupo;  -- Asegurarse de agrupar tambi├®n por el ID del horario
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CREAR_USUARIO` (IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255), IN `p_fullName` VARCHAR(255), IN `p_activo` INT, IN `p_rolAdmin` INT, IN `p_rolServicio` INT, IN `p_rolContable` INT, IN `p_rolReporteria` INT)   BEGIN
    DECLARE userID INT;

    -- Insertar el nuevo usuario
    INSERT INTO usuarios (Email, Password, FullName, IsActive) 
    VALUES (p_email, p_password, p_fullName, p_activo);

    -- Obtener el ID del usuario reci├®n creado
    SET userID = LAST_INSERT_ID();

    -- Asignar los roles al usuario
    IF p_rolAdmin = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID) VALUES (userID, 1);  -- 1 para rolAdmin
    END IF;

    IF p_rolServicio = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID) VALUES (userID, 2);  -- 2 para rolServicio
    END IF;

    IF p_rolContable = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID) VALUES (userID, 3);  -- 3 para rolContable
    END IF;

    IF p_rolReporteria = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID) VALUES (userID, 4);  -- 4 para rolReporteria
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_EDITAR_USUARIO_V2` (IN `p_usuarioID` INT, IN `p_email` VARCHAR(255), IN `p_password` VARCHAR(255), IN `p_fullName` VARCHAR(255), IN `p_rolAdmin` INT, IN `p_rolServicio` INT, IN `p_rolContable` INT, IN `p_rolReporteria` INT, IN `p_activo` BIT)   BEGIN
    -- Actualizar los datos del usuario
    UPDATE usuarios 
    SET Email = p_email, 
        Password = p_password, 
        FullName = p_fullName,
        IsActive = p_activo    -- Actualizar el estado de activaci├│n
    WHERE ID = p_usuarioID;

    -- Actualizar o eliminar los roles seg├║n los valores pasados

    -- Actualizar o insertar rol de Administrador
    IF p_rolAdmin = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID)
        SELECT p_usuarioID, 1
        FROM DUAL
        WHERE NOT EXISTS (SELECT 1 FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 1);
    ELSE
        DELETE FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 1;
    END IF;

    -- Actualizar o insertar rol de Servicio al cliente
    IF p_rolServicio = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID)
        SELECT p_usuarioID, 2
        FROM DUAL
        WHERE NOT EXISTS (SELECT 1 FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 2);
    ELSE
        DELETE FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 2;
    END IF;

    -- Actualizar o insertar rol de Contable
    IF p_rolContable = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID)
        SELECT p_usuarioID, 3
        FROM DUAL
        WHERE NOT EXISTS (SELECT 1 FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 3);
    ELSE
        DELETE FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 3;
    END IF;

    -- Actualizar o insertar rol de Reporter├¡a
    IF p_rolReporteria = 1 THEN
        INSERT INTO usuarios_roles (UsuarioID, RoleID)
        SELECT p_usuarioID, 4
        FROM DUAL
        WHERE NOT EXISTS (SELECT 1 FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 4);
    ELSE
        DELETE FROM usuarios_roles WHERE UsuarioID = p_usuarioID AND RoleID = 4;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_RevertirPago` (IN `p_id_movimiento` INT, IN `p_id_matricula` INT)   BEGIN
    DECLARE movimientoExiste INT;

    -- Verificar si el movimiento existe
    SELECT COUNT(*) INTO movimientoExiste
    FROM movimientosdinero
    WHERE id = p_id_movimiento;

    IF movimientoExiste = 0 THEN
        -- Lanzar error si no existe el movimiento
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: El movimiento con el ID proporcionado no existe.';
    ELSE
        -- Eliminar el movimiento
        DELETE FROM movimientosdinero WHERE id = p_id_movimiento;

        -- Actualizar la matrícula sumando 1 a cuotasPendientes
        UPDATE matriculas
        SET cuotasPendientes = cuotasPendientes + 1
        WHERE Id = p_id_matricula;
    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ValidarCuotasPagadasEnvioMensaje` (IN `idMatricula` INT)   BEGIN
    DECLARE CuotasPendientes INT;
    DECLARE CantidadCuotas INT;
    
    -- Obtener las cuotas pendientes de la matrícula
    SELECT cuotasPendientes INTO CuotasPendientes
    FROM matriculas
    WHERE Id = idMatricula;
    
    -- Obtener la cantidad total de cuotas del curso asociado
    SELECT c.cantidadCuotas INTO CantidadCuotas
    FROM cursos c
    INNER JOIN matriculas m ON c.ID = m.Id
    WHERE m.Id = idMatricula;
    
    -- Comparar valores y retornar el resultado
    IF CuotasPendientes = CantidadCuotas THEN
        SELECT 1 AS Resultado;
    ELSE
        SELECT 0 AS Resultado;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ValidarYInsertarHorario` (IN `p_DiaSemana` VARCHAR(20), IN `p_HoraInicio` TIME, IN `p_HoraFin` TIME, IN `p_IdCurso` INT, IN `p_IdProfesor` INT, IN `p_Cupo` INT, OUT `p_Resultado` INT, OUT `p_Mensaje` VARCHAR(255))   BEGIN
    -- Verificar si ya existe un horario con la misma combinaci├│n de d├¡a, hora y profesor
    IF EXISTS (
        SELECT 1 FROM horarios_cursos
        WHERE DiaSemana = p_DiaSemana
        AND ((HoraInicio <= p_HoraInicio AND HoraFin > p_HoraInicio) 
            OR (HoraInicio < p_HoraFin AND HoraFin >= p_HoraFin))
        AND IdProfesor = p_IdProfesor
    ) THEN
        SET p_Resultado = -1;
        SET p_Mensaje = 'Ya existe un horario asignado a este profesor en ese horario.';
    ELSE
        -- Insertar el nuevo horario si no hay conflicto
        INSERT INTO horarios_cursos (DiaSemana, HoraInicio, HoraFin, IdCurso, IdProfesor, Cupo)
        VALUES (p_DiaSemana, p_HoraInicio, p_HoraFin, p_IdCurso, p_IdProfesor, p_Cupo);
        
        SET p_Resultado = 0;
        SET p_Mensaje = 'Horario insertado correctamente.';
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bitacoria_clientes`
--

CREATE TABLE `bitacoria_clientes` (
  `CONSECUTIVO` int(11) NOT NULL,
  `NOMBRE` varchar(100) NOT NULL,
  `CEDULA` varchar(20) NOT NULL,
  `TELEFONO` varchar(15) DEFAULT NULL,
  `CORREO` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `bitacoria_clientes`
--

INSERT INTO `bitacoria_clientes` (`CONSECUTIVO`, `NOMBRE`, `CEDULA`, `TELEFONO`, `CORREO`) VALUES
(15, 'Elizabeth Campos Hernández ', '108160250', '50683436720', 'camposeli@hotmail.es'),
(16, 'Ana Porras Segura', '110210125', '50685974692', 'anacripo@hotmail.com'),
(17, 'Carmen Murillo Espinoza', '20482781', '50689873903', 'carmenmurilloespinoza@gmail.com'),
(18, 'Guadalupe Murillo Espinoza', '2473966', '50685068415', 'murillog972@gmail.com'),
(19, 'Laura Ugalde Calvo ', '113340646 ', '50672193934', 'lauugalde36@yahoo.com'),
(20, 'Catalina Sánchez Sánchez ', '206690166', '50683345869', 'cata23ss@hotmail.com'),
(21, 'Carla Hernández Solís', '602470850', '50689325062', 'karlahs1872@gmail.com'),
(22, 'Patricia Bermudez Ramírez ', '107700528', '50688472954', 'patribr14@gmail.com'),
(23, 'Milena Mendoza Valenciano', '701100837', '50689932919', 'mmendoza@una.ac.cr'),
(24, 'María de los Ángeles Ríos Obando', '1-1116-0992 ', '50671036841', 'anais2409@gmail.com'),
(25, 'Laura Moreno González ', '401870046', '50663604228', 'laumoreno237@gmail.com'),
(26, 'Tamara Campos Rodriguez', '402700009', '50672703203', 'myrna.rodriguezn2@gmail.com'),
(27, 'Myrna Rodriguez', '112340856', '50671241023', 'myrrn20@icloud.com'),
(28, 'Carla Hernández Solis', '6247850', '50689325062', 'karlahs1872@gmail.com'),
(29, 'Valentina gabriela Morales Sánchez ', '402730546', '50684490254', 'valentinagabriela1406@gmail.com'),
(30, 'Marianela Cerdas Gómez ', '402070781', '50685501226', 'nelac0809@gmail.com'),
(31, 'Jesenia Torres Vargas', '117870417', '50686264451', 'jestorres03@hotmail.com'),
(32, 'Patricia Suarez Jimenez ', '110800493', '50684080045', 'Patisuji80@gmail.com'),
(33, 'Miriam Salas Arce ', '108410277', '50672134027', 'mirsalasa@gmail.com'),
(34, 'Viviana Cerdas Gómez ', '207450030', '50689778594', 'vivianacerdasgomez@gmail.com'),
(37, 'Krysta Nicole Navarro Carvajal', '117640290', '50687842662', 'nicolnc02@gmail.com'),
(38, 'Irene Villalobos León', '402110502', '50689158623', 'ire_villalobos_18@hotmail.com'),
(39, 'Marjorie Bonilla Benavides ', '1-0621-0927 ', '50683496850', 'yuriboni64@gmail.com'),
(40, 'Elizabeth Vargas López ', '104520944', '50661148230', 'marieliza317@gmail.com'),
(41, 'Dayanna Aguilar Brenes ', '603050700', '50688273519', 'dayannaa3@gmail.com'),
(42, 'Marian Carillo Valverde ', '111560465', '50670155093', 'valerysala07@gmail.com'),
(43, 'Paola Vargas', '109600558', '506', 'jpavazu@gmail.com'),
(44, 'Diana Rojas Alpízar ', '205050645', '50670872884', 'diana121075@hotmail.com'),
(45, 'Tiffany Ramírez Leitón ', '119810016', '50686881003', 'tiffarl10@gmail.com'),
(46, 'José Mario Valerio Berrocal ', '401940089', '50684553578', 'jvalerio419@gmail.com'),
(47, 'Marcela Arce Espinoza', '108060527', '50686677561', 'marcearceespinoza@gmail.com'),
(48, 'Patricia Ramírez Rimolo ', '108270565 ', '50670395794', 'masiescara98@gmail.com'),
(49, 'Masiel Escalante Ramírez ', '402370817', '50663786607', 'masiescara98@gmail.com'),
(50, 'Vanessa Rodríguez Serrano ', '303750678', '50661481859', 'vrs3981@hotmail.com'),
(51, 'Kerlyn Fernández Obando ', '112860687', '50683193219', 'kerlyn_07@yahoo.es'),
(52, 'Angelica Ramirez', '304410397', '50683032314', 'arami13@gmail.com'),
(53, 'Maria de Guadalupe Estrada Medrano', 'Pasaporte N08039338', '50672354223', 'ing.guadalupe.estrada@gmail.com'),
(54, 'Yinyer morales Sibaja', '111970241', '50664837504', 'gingerms1984@gmail.com'),
(55, 'Karen Camacho Valerio', '401840724', '50688103763', 'kata1308@gmail.com'),
(56, 'Gabriela', '114540370', '50689636300', 'gabrielamatag@outlook.com'),
(57, 'Greidy Hernández Esteban ', '113620824', '50670119590', 'greidy.hernandez@hotmail.com'),
(58, 'Gabriela Mata Gamboa ', '114540360', '50689636300', 'gabrielamatag@outlook.com'),
(59, 'Valeria campos lobo', '402210923', '50672041477', 'valecl2693@gmail.com'),
(60, 'Elodia Hernandez Vargas ', '401440460 ', '50687830596', 'elo.her@hotmail.es'),
(61, 'Doris Carolina Rodríguez Ramírez', '112780769', '50683467785', 'dorys18@gmail.com'),
(62, 'Karen Herrera Sandi', '117830143', '50684158568', 'kherrera0520@gmail.com'),
(63, 'DAYANNA ', '117750879', '50688920041', 'calicalderon09@gmail.com'),
(64, 'Cinthya Hypatia Gutiérrez Abarca ', '801090982', '50664516749', 'cinlayj2@gmail.com'),
(65, 'Sharon Gustavina Arce ', '402870905', '50685574353', 'alelobo4060@gmail.com'),
(66, 'Ligia Brenes Elizondo', '502200753', '50688102040', 'ligia.bre@gmail.com'),
(67, 'Carolina Barquero Brenes ', '401850396', '50683346472', 'cvjbarquero@gmail.com'),
(68, 'Catalina Jiménez Ramírez', '113250320', '50684984125', 'catalinajimenezr13@gmail.com'),
(69, 'Mercedes Manzanares Barahona', '800770707', '50687922465', 'william.Bermudez.ramirez@gmail.com'),
(70, 'Dafnaly Mitre Hernandez', '702680854', '50664181317', 'dafmh1228@gmail.com'),
(71, 'Marycruz Ocampo Aguilar ', '108080245', '50688388581', 'maricruzocampo@yahoo.es'),
(72, 'Norma Moreira Chaves', '105740788', '50688304982', 'nmoreirach@gmail.com'),
(73, 'Flor María Vega Rojas ', '108950861', '50660062099', 'florvega010@gmail.com'),
(74, 'Karol Chinchilla Barrientos', '109900292', '50687053610', 'karolchiba40@gmail.com'),
(75, 'Laura Moreno González ', '401870945', '50663604228', 'laumoreno237@gmail.com'),
(76, 'Lidia Ramírez Bogantes ', '401950754 ', '50688792586', 'lidiramiboga25@hotmail.com'),
(77, 'Concepción de los angeles González galan ', '155818926626', '50672982489', 'concegonzalez85@gmail.com'),
(78, 'Anayanci Hernandez ', '401880312', '50688820808', 'yanci0723@gmail.com'),
(79, 'Silvia Ruiz Hernandez ', '106330197', '50683547496', 'majorh_123@outlook.com'),
(80, 'Carmen Salazar Torres', '402340174', '50686918249', 'cbeatriz1797@gmail.com'),
(81, 'Ligia Varela Muñoz ', '107370254 ', '50688057888', 'vivivarela68@gmail.com'),
(82, 'Maricel Rodriguez Serrano ', '303330605 ', '50686195081', 'maricel111974@gmail.com'),
(83, 'Dayanna Garcia sanchez ', '23449451', '50688920041', 'calicalderon09@gmail.com'),
(84, 'Natalie Ramos Campos ', '4 0282 0851', '50662912560', 'vivi.camposh@gmail.com'),
(85, 'Isabel Cristina Rosales Chavarría ', '108390723', '50688238231', 'isabelrosales2910@hotmail.com'),
(86, 'Marjorie Ruiz Hernandez ', '107510249', '50683547496', 'majorh_123@outlook.com'),
(87, 'Alanis Camila Arce Lobo ', '402760839', '50660649951', 'arcecamila730@gmail.com'),
(88, 'Guadalupe concepción Hernández sandino ', '402300929', '506', 'lupitasandino41117@gmail.com'),
(89, 'Guisela Murillo Cubero', '111630431', '50671300518', 'guiselamurillo12@gmail.com'),
(90, 'Guisela Murillo Cubero', '111620431', '50671300518', 'guiselamurillo12@gmail.com'),
(91, 'Ana Isabel Mora Romero', '10710-0406.', '50689165559', 'anita60mr@gmail.com'),
(92, 'Katherine Siles Madrigal', '110590914', '50683119972', 'kathysilesm20@gmail.com'),
(93, 'Karen García Quirós ', '118720579', '50672416747', 'karengarciaquiross@gmail.com'),
(94, 'Ingrid Gutiérrez Rojas', '701910282 ', '50688800148', 'ingridgr2022@gmail.com'),
(95, 'Dayanna García Sánchez ', '0117750879', '50688920041', 'calicalderon09@gmail.com'),
(96, 'Brittany Sanchez ', '4 02690283', '50662486415', 'brisj10909m@gmail.com'),
(97, 'Pruebas Desarrollo', '123123123123', '50612312312', 'desarrollo@gmail.com'),
(98, 'desarrollo', '22123123', '50622123123', '22123123@gmail.com'),
(99, 'desarrollo', '123123', '506123123', '123123'),
(100, 'Hellen Alvarado Mora ', '11005230', '50660294024', 'hellenalvarado.528@gmail.com'),
(101, 'Yamileth Arce Barquero', '401380433', '50683391283', 'yarcebarquero@gmail.com'),
(102, 'Katthya Trejos Zamora', '401480554 ', '50688831919', 'trejoskz68@gmail.com'),
(103, 'Xinia Arguedas Vega ', '2 462 507', '50671435344', 'xiniarguedas45@gmail.com'),
(104, 'Ana Leticia Chaves Ramírez ', '401480834', '50687292738', 'alei353@hotmail.com'),
(105, 'Wendy Lorena raudales moncada ', '801270603 ', '50685765304', 'wendyraudalesm@gmail.com'),
(106, 'Mariela Rojas Calderón ', '113830662', '50687681082', 'marie2489@gmail.com'),
(107, 'Hazel Argüello Guerrero', '604600552', '50685862323', 'hazelarguelloguerrero27@gmail.com'),
(108, 'Tatiana María Arce Ramirez ', '402100180 ', '50670282748', 'arcem9269@gmail.com'),
(109, '312312312', '312312312', '50631231231', 'pruebas@desarrollo.com'),
(110, '342323', '234234', '50688892680', '234234'),
(111, 'Jessica Montero Morales', '106790295', '50660407375', 'jemonteromorales@gmail.com'),
(112, 'Kelly Jexabell sequeira areas', '155802404327', '506', 'kelly.s.areas94@gmail.com'),
(113, 'Jose Redondo', 'pruebas', '50688195365', 'pruebas@gmail.com'),
(114, '43342', '342342', '50634234234', '234234'),
(115, 'Andrea León López ', '115400953', '50672082849', 'andylopstar15@gmail.com'),
(116, 'Mónica Albonico Araya', '107160047', '50689824740', 'monicalbonico@gmail.com'),
(117, 'Jose Redondo', '123123123', '50688195365', 'joser2320@gmail.com'),
(118, 'Martha León López ', '14740370', '50670815196', 'marthaleolop@gmail.com'),
(119, 'Yancy Villalobos ', '401750832 ', '50685966794', 'yancyvch21@gmail.com'),
(120, 'Mónica Hernández Paniagua ', '115830332 ', '50685589568', 'hernandezmoni22@hotmail.com'),
(121, 'Yendry Miranda D', '111490268', '50660509008', 'agosto2482@gmail.com'),
(122, 'Pamela Quiros', '116680534', '50660761584', 'pamelaquiros9712@gmail.com'),
(123, 'Maria celeste Mena Sanabria ', '402370245', '50672910923', 'celestems131@gmail.com'),
(124, 'Cecilia Dolores Arauz Robleto', '800460437', '50664790267', 'ceciarauz50@gmail.com'),
(125, 'Adriana Mora Fallas ', '108370010', '50688311301', 'amorafa25@gmail.com'),
(126, 'Thaylin Zúñiga ', '604640538', '50684878814', 'zthay10@gmail.com'),
(127, 'Patricia Monge Bonilla', '105980500', '50683948747', 'Patricia2357@outlook.es'),
(128, 'Stephanie Jiménez Lobo ', '402370177', '50670566405', 'stephanie.m.jim@outlook.es'),
(129, 'Silvia Vargas Hernández ', '401860689 ', '50685473391', 'mivanpri24@gmail.com'),
(130, 'Adriana Solano', '114160446', '50683082659', 'adri31sc@gmail.com'),
(131, 'Pamela Álvarez ', '402390755', '50684206680', 'pamelaalvrz04@gmail.com'),
(132, 'Dylan Arce Vargas ', '402240373', '5067137653', 'dylavargas94@gmail.com'),
(133, 'Fabiola Ninoska Flores Taleno ', '801150817', '50660632350', 'fabiolaflores18@gmail.com'),
(134, 'María Eugenia Gómez Ulloa ', '700520983', '50664810588', 'marigu5477@gmail.com'),
(135, 'Betsabeth corea miranda', '206520889', '50684183435', 'betsabeth2012@gmail.com'),
(136, 'Ingrid gabriela Mena Matarrita', '701730020', '50684780456', 'gabymena045@gmail.com'),
(137, 'Ana Victoria López Sánchez ', '112130362', '50685837681', 'lopesanchezvictoriana@gmail.com'),
(138, 'Guisselle Cambronero León ', '401730092 ', '50686051200', 'gleon18@gmail.com'),
(139, 'Amanda Picado Espinoza ', '402730901', '50672380699', 'emi.picado06@gmail.com'),
(140, 'Thaylin Zúñiga León', '604640539', '50684878814', 'zthay10@gmail.com'),
(141, 'Marianella Eduarte Rodríguez', '402040464', '506', 'nelaer221189@gmail.com'),
(142, 'Josseline Daniela Jiménez Rodríguez', '402480522', '50661039812', 'josseline649@gmail.com'),
(143, 'Adriana Durán Villalobos ', '402200967', '50670157613', 'duranvillalobosadri@gmail.com'),
(144, 'Grettel Barrios Barrientos ', '114850081', '50662428017', 'grettelbarriosaj@gmail.com'),
(145, 'MELANY AGUILAR ARGUELLO', '113620190', '50685643372', 'melanytatiana88@gmail.com'),
(146, 'Fiorella Chacón Alpizar ', '402390808', '50663741538', 'fiochacon10@hotmail.com'),
(147, 'Katthy Rodríguez Madrigal', '109890117', '50660331077', 'katthyarodriguezcr@hotmail.com'),
(148, 'María Gabriela Frias Chaves', '107440899', '50688804471', 'gabyfriaschaves@hotmail.com'),
(149, 'Jenny Beatriz Zeledón Zúñiga', '401770098', '50689161701', 'zeledonj09@yahoo.com'),
(150, 'Patricia Chavarría Villegas', '401280772', '50663953227', 'patriciach142@gmail.com'),
(151, 'Yensy Meza Cortés', '303400924', '50683083268', 'yensymeza22@gmail.com'),
(152, 'Leda Rodríguez Ruíz ', '302600543', '50670151084', 'leroru04@gmail.com'),
(153, 'Xinia Arguedas vega', '2462507', '50671435344', 'xiniarguedas45@gmail.com'),
(154, 'Erika Isabel Lopez Mejia', '155813950517', '50688617062', 'lopezmejiaerika8@gmail.com'),
(155, 'Geovanna Vanessa Córdoba Prendas ', '111900813', '50686461346', 'g.vane081318@gmail.com'),
(156, 'Elsa Araya Chavarría ', '602320635', '50688664541', 'elsaa2@gmail.com'),
(157, 'Wendy Campos Rodríguez', '402140567', '50670568174', 'wen.camp141@gmail.com'),
(158, 'Daniela Arce Murillo', '402040945', '50689911697', 'Danielaam2@hotmail.com'),
(159, 'Danna Paola Castillo Villalobos ', '1 1908 0280', '50687490111', 'dannacastillov2004@gmail.com'),
(160, 'Danna Paola Castillo Villalobos ', '119080280', '50687490111', 'dannacastillov2004@gmail.com'),
(161, 'Heisel Martinez Salgado', '109490626', '50687437876', 'heisel120976@gmail.com'),
(162, 'Nayeli ', '402610041', '50663212216', 'nayelissoto049@gmail.com'),
(163, 'Lorena Cubillo Lobo ', '106210599', '50688950020', 'lorenacubillo93@gmail'),
(164, 'Yorleny Fernández ', '107500884', '50685898621', 'darialexa99@gmail.com'),
(165, 'Yaireth Arias Aguilar ', '401840532', '50687385271', 'yary0584@gmail.com'),
(166, 'Milena Espinoza Rojas ', '4-0180-0485 ', '50660565826', 'milenaer12@gmail.com'),
(167, 'María Elena Ramírez Ramírez', '402350139', '50689644084', 'mr84704@gmial.com'),
(168, 'Ana Jen Camacho Soto', '401070669', '50684416868', 'radiobarvacr@gmail.com'),
(169, 'Glenda Miranda Román', '402250682', '50685634514', 'glenda.mr04@gmail.com'),
(170, 'Marvin Andrei González Vargas ', '116280215', '50687160815', 'marvin95112009@hotmail.com'),
(171, 'Lourdes mora soto', '205470593', '50670521224', 'lourdesmorasoto@gmail.com'),
(172, 'Tatiana Villafuerte Retana ', '402490573 ', '50660060595', 'tvillafuerte.04@outlook.com'),
(173, 'Xinia Alfaro Bonilla', '401480881', '50688788428', 'xaxalfaroo@gmail.com'),
(174, 'María Patricia Conejo Rojas', '204220150', '50689894536', 'patriciaconejo@hotmail.com'),
(175, 'Melissa García Rodríguez ', 'E023105', '50663038834', 'mr8012793@gmail.com'),
(176, 'Magaly Solorzano Guerrero ', '701590004', '50687518714', 'maga.gata35@gmail.com'),
(177, 'Sussana Bolaños Villalobos ', '401940399', '50664887766', 'mariakpuravida2018@gmail.com'),
(178, 'Karina Esquivel Solano ', '110970348', '50685491849', 'kriness@gmail.com'),
(179, 'Ileana Cordero León', '401620477', '50685468134', 'ilecorleo@yahoo.com'),
(180, 'Martha Elena Meléndez Monge', '106700550', '50688206921', 'marthammonge@hotmail.com'),
(181, 'Ariela Garita Flores', '120720203', '50685384177', 'floreslucy08@gmail.com'),
(182, 'Lucía Flores Fonseca', '111260671', '50688323567', 'floreslucy08@gmail.com'),
(183, 'Maribel Berrocal Miranda', '401400554', '50688104611', 'mirandapalmamarielos@gmail.com'),
(184, 'Deyanira Castillo Chaves', '401390551', '50684657497', 'deyacastillo2@gmail.com'),
(185, 'María Fernanada Urra Sánchez', '112180758', '50685655826', 'mariger_urra@hotmail.com'),
(186, 'Marifer Estrada Altamirano ', '504370383', '50664852116', 'estrada.altamirano20marifer@gmail.com'),
(187, 'Shirley Patricia Marín Muñoz ', ' 106780125', '50683713717', 'shmarin13@hotmail.com'),
(188, 'flor maria cascante Fernández', '50688820390', '50688820390', 'Fmcasf@gmail.com'),
(189, 'Susan Melissa Moya Sánchez', '112440248', '50689122239', 'moyasanchezmelissa@gmail.com'),
(190, 'Flor María Cascante Fernández', '104130614', '50688820390', 'fmcasf@gmail.com'),
(191, 'Melany Montero Rivera', '402540870', '50661679051', 'melanymonterorivera@gmail.com'),
(192, 'Andrea Vega Morales', '603820205', '50689073506', 'keizu08@gmail.com'),
(193, 'Kristal Brillit León Orellana ', '402620221 ', '50686420135', 'oreleonkriss80@gmail.com'),
(194, 'Silvia Orellana Díaz', '122200475400', '50662386651', 'orellanasilvia5050@gmail.com'),
(195, 'Bella Lorena Rivas Sosa', '122200041931', '50687645626', 'blrivassosa@gmail.com'),
(196, 'Jacqueline Gutiérrez Duarte', '401740279', '50670196887', 'jackeline.g.d.81@gmail.com'),
(197, 'Maribel Sánchez Azofeifa ', '111230176 ', '50683996796', 'maribellsna@gmail.com'),
(198, 'Giuliana Sophía Vargas Mendoza', '119880006', '50660071602', 'vargasgiuliana1602@gmail.com'),
(199, 'María Yael Solano Méndez', '108860142', '50683133584', 'yaelita2806@gmail.com'),
(200, 'Angelita Valerio Sánchez', '108300643', '50686132525', 'avalerio48@hotmail.com'),
(201, 'Kimberly Lhamas Mohs', '112180858', '50663089531', 'kimlhamasmohs@gmail.com'),
(202, 'Tracy Montero Mora', '115430513', '50683891276', 'nanim264@gmail.com'),
(203, 'Pricilla Vargas González', '401960112', '506', 'prixi410@gmail.com'),
(204, 'Mariela Chaves Arias', '401970264', '50685044046', 'chaves.mari.sr@gmail.com'),
(205, 'Silvia Ramírez Zúñiga', '108430014', '50672010885', 'sramirezz@yahoo.es'),
(206, 'Valery Rebeca Vargas Segura', '402580327', '50685455802', 'valesegura341@gmail.com'),
(207, 'Jeannette Chavarría Campos', '106320197', '50661193507', 'jecacha17@hotmail.com'),
(208, 'Habraham Miranda Morales', '402810689', '50661711537', 'estrellamoralesbrenes344@gmail.com'),
(209, 'Catalina Vargas Hernández', '115770102', '50687233561', 'cata07vh@gmail.com'),
(210, 'Eveling Juniette Suazo Romero', '155826823226', '50685997639', 'juniethsuazo@gmail.com'),
(211, 'Flordeliz Vega Alavarado', '401780380', '50663126760', 'fvega2354@gmail.com'),
(212, 'Zaray Chavez Ocampo', '402340709', '50672609955', 'zaraychavesocampo@gmail.com'),
(213, 'Martha León López', '104740370', '50670815196', 'marthalelop@gmail.com'),
(214, 'Leticia Villalobos Ramírez', '108760100', '50683379728', 'lvillalobos032@hotmail.com'),
(215, 'Elieth Sánchez Chaves', '900640223', '50688958810', 'macha2631@gmail.com'),
(216, 'Yajaira Garro González', '401690916', '50688268104', 'yayigarro@yahoo.com'),
(217, 'Verónica Dubón Vanegas', '134000227829', '50688831870', 'facturaciondigital2020gmail.com'),
(218, 'Karla Marcela Campos Cortés', '401690527', '50664561271', 'kc411292@gmail.com'),
(219, 'Kassandra Arias Lindor', '402290565', '50685505319', 'ariaslindork@gmail.com'),
(220, 'María José Sanabria Garro', '113380724', '50683380999', 'mjsanabria03@gmail.com'),
(221, 'Nicole Brenes Solís', '118080544', '50684130962', 'nicolbrso1204@gmail.com'),
(222, 'Paola Solís Meza', '114730485', '50662970706', 'jenepao460@gmail.com'),
(223, 'Susana Segura Cortés', '401990430', '50688365492', 'susansc45@gmail.com'),
(224, 'Nicole Melissa Solís Salgado', '117850083', '50664723689', 'melissasolis0770@gmail.com'),
(225, 'Daniela María Oconitrillo Garita', '402020212', '50688194962', 'daniocog@gmail.com'),
(226, 'María Delgado Calderón', '108320445', '50672605455', 'maria.delg.7389@gmail.com'),
(227, 'Verónica Patricia Gudiel Solís', '116730814', '50671927475', 'vgudiel662@gmail.com'),
(228, 'Ana Victoria Vásquez Anchía', '401880650', '50661665281', 'avictoria85@gmail.com'),
(229, 'Evelyn Daniela Alfaro Fonseca', '402330790', '50689689013', 'eve_alfaro@hotmail.com'),
(230, 'Diana Vanessa Jirón Dávila', '155840672617', '50672957820', 'dianavanessadavila@gmail.com'),
(231, 'Micaela Camacho Vargas', '401061096', '50689110888', 'micaelacv13@gmail.com'),
(232, 'Abril Gabriela Vindas Castro', '402550825', '50672868191', 'avindas2014@gmail.com'),
(233, 'Saily Sandoval Ramírez', '402330457', '50683872688', 'sailysandovalr@gmail.com'),
(234, 'Ana Ligia Monge Quesada', '301971133', '50688356135', 'analigiamongeq@gmail.com'),
(235, 'Adrián Pérez Mendoza', '402820392', '50687347775', 'mendozamarbellys44@gmail.com'),
(236, 'Tamara Moreno Ureña', '114600452', '50672901911', 'tamaramoreno26@hotmail.com'),
(237, 'Maricel Acuña Marín', '401860213', '50688709645', 'mari1126@hotmail.es'),
(238, 'Catalina Campos Cortés', '402190103', '50661127211', 'catalinacampos066@gmai.com'),
(239, 'Ana Isabel Reyes Herra', '106360220', '50683825341', 'anareyesherra@outlook.com'),
(240, 'Yendry Díaz Valverde', '701670581', '50663562510', 'yendrydiazv@gmail.com'),
(241, 'Karol Gómez Cortés', '304260599', '50671675305', 'karo881414@gmail.com'),
(242, 'María Fernanda Pérez Chavarría', '402130665', '50688010207', 'fernanda23.23@hotmail.com'),
(243, 'Yareliz Alvardao Cambronero', '114320172', '50686504693', 'yarelizac@hotmail.com'),
(244, 'Ana Isabel Cruz Cruz', '700550620', '50687123608', 'casmanuel1@yahoo.com'),
(245, 'Dayana Alfaro Esquivel', '401970615', '50672032960', 'daalfaroe@gmail.com'),
(246, 'Josebeth Arrieta Zúñiga', '402750635', '50686084624', 'jojoarixx@gmail.com'),
(247, 'Cindy Gutiérrez Abarca', '402360387', '50689525072', 'gutierreza.facturas@gmail.com'),
(248, 'Verónica Guevara Corrales ', '111030051', '50688272555', 'veronik29@yahoo.com'),
(249, 'Rose Miranda González', '110410474', '50687058435', 'odontomundo@yahoo.com'),
(250, 'Gabriela Arce Rubí', '108080542', '50689229987', 'garce0211@gmail.com'),
(251, 'Yamileth Ruíz Vargas', '104630531', '50688606307', 'yami@transportes-chaves.com'),
(252, 'María Fernanda Alvarado Jiménez', '116000228', '50684503385', 'andreysolis8916@gmail.com'),
(253, 'María de los Ángeles Miranda Palma', '401080393', '50688104611', 'mirandapalmamarielos@gmail.com'),
(254, 'Mariana Sánchez Paniagua', '402300619', '50660049256', 'marisanchez-1996@hotmail.com'),
(255, 'María Luisa Acosta Zárate', '119950153', '50660142698', 'malua2007@gmail.com'),
(256, 'Gisela Espinoza Avelares', '155819996611', '50661675144', 'giseespinoza94@hotmail.com'),
(257, 'Lourdes María Arce Espinoza', '401560689', '50683043666', 'arcelourdes1@gmail.com'),
(258, 'Graciela Carolina Medrano Aburto', 'C03828961', '50672669943', 'medranograciela156@gmail.com'),
(259, 'María de los Ángeles Hernández Hernández', '401320083', '50685461917', 'marieloshernandez086@gmail.com'),
(260, 'Ana Jiménez Arroyo', '109590444', '50688897595', 'infogrupoakara@gmail.com'),
(261, 'Samantha Araya Jiménez', '402800481', '50663771187', 'saudyjisa87@otlook.es'),
(262, 'Joselin Chen Chaves ', '604470170', '50687239696', 'joselynchen24@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cursoimagen`
--

CREATE TABLE `cursoimagen` (
  `idImagen` int(11) NOT NULL,
  `cursoID` int(11) DEFAULT NULL,
  `urlImagen` varchar(255) NOT NULL,
  `fechaCreacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cursoimagen`
--

INSERT INTO `cursoimagen` (`idImagen`, `cursoID`, `urlImagen`, `fechaCreacion`) VALUES
(17, 14, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F14%2FALMOHADONES%20-%20PRINCIPIANTES.jpg?alt=media&token=d6021c3b-5654-4b7f-9342-1ed7b6a0b138', '2025-03-10 19:50:58'),
(18, 16, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F16%2FGLOBOS%20-%20B%C3%81SICO.jpg?alt=media&token=48c318e2-f333-4c0b-b56a-e40b39cf49cd', '2025-03-10 19:51:22'),
(19, 17, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F17%2FGLOBOS%20-%20AVANZADO.jpg?alt=media&token=17f7a7ca-5c3b-4835-96df-7f1172364060', '2025-03-10 19:51:36'),
(21, 15, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F15%2FALMOHADONES%20-%20INTER%20-%20AVANZ.jpg?alt=media&token=f3d535ce-2e14-4889-a2e8-6389cfab044c', '2025-03-12 16:57:50'),
(22, 19, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F19%2FCOSM%C3%89TICA%20NATURAL.jpg?alt=media&token=e6cb6ea3-08bf-436a-b585-83426ca20435', '2025-03-12 16:58:12'),
(23, 22, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F22%2FJABONER%C3%8DA.jpg?alt=media&token=e7338b5e-599c-4c30-9d98-87423e66a78b', '2025-03-12 16:58:27'),
(25, 25, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F25%2FVESTIDOS%20DE%20BA%C3%91O.jpg?alt=media&token=002d7d82-3cc8-40b0-8a61-68642f9a8e6c', '2025-03-12 16:58:53'),
(26, 27, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F27%2FCOSTURA%20DESDE%20CERO%20B%C3%81SICO.jpg?alt=media&token=304da1e1-21b0-495c-9e90-fe3f0f06b7b3', '2025-03-12 16:59:13'),
(27, 26, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F26%2FCOSTURA%20DESDE%20CERO%20INTERMEDIO.jpg?alt=media&token=8cf08a63-77df-421a-bbab-d2a70e58696c', '2025-03-12 17:00:03'),
(28, 28, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F28%2FBORDADO.jpg?alt=media&token=b74cfd69-cc5c-4ee6-8f6a-7d0fa0171e56', '2025-03-12 22:44:55'),
(30, 32, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F32%2FMANICURE%20PROFESIONAL.jpg?alt=media&token=c4a0ae21-c881-479b-929c-e03f3bc7d6e2', '2025-03-12 22:45:33'),
(31, 38, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F38%2FPORTUGU%C3%89S.jpg?alt=media&token=62c25a1e-6270-4074-ab13-ccf4f143efea', '2025-03-12 22:45:51'),
(32, 39, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F39%2FCURSO%20PANADER%C3%8DA%20B%C3%81SICO.jpg?alt=media&token=24092591-57b0-47a1-8e19-fc01745f52a1', '2025-03-12 22:46:30'),
(33, 40, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F40%2FALAMBRISMO%20B%C3%81SICO.jpg?alt=media&token=d89ff3f3-885d-4707-8295-ff1efdbb924c', '2025-03-12 22:46:46'),
(36, 42, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F42%2FPANADER%C3%8DA.jpg?alt=media&token=1b4e8dc3-bffd-45fe-a045-22034e9017b2', '2025-03-14 15:01:18'),
(37, 43, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F43%2FPASTELER%C3%8DA%20PRINCIPIANTES.jpg?alt=media&token=ae3ddd0b-e5ce-4524-8f2d-c4de438890c9', '2025-03-14 15:01:35'),
(38, 44, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F44%2FREPOSTER%C3%8DA.jpg?alt=media&token=1b500ac7-a73d-4a5b-b60c-a2e04b28200d', '2025-03-14 15:01:52'),
(39, 45, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F45%2FPASTELER%C3%8DA%20NIVEL%202.jpg?alt=media&token=b3aa11d6-9825-403d-8959-f214218e3b23', '2025-03-14 15:02:09'),
(40, 18, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F18%2FCOSTURA%20Y%20PATRONAJE.jpg?alt=media&token=5c2c1cc8-2685-4d4c-bdf6-cd47a4045ffd', '2025-03-14 15:07:43'),
(41, 31, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F31%2FQUILTING.jpg?alt=media&token=54eecd32-db91-4c7e-a026-30e1b85a38d4', '2025-03-14 23:32:19'),
(42, 35, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F35%2FCANVA%20VIRTUAL.jpg?alt=media&token=eeebedd6-cd27-46eb-b260-3be103fd7535', '2025-03-21 16:48:18'),
(43, 36, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F36%2FCANVA%20AVANZADO.jpg?alt=media&token=9c769431-b156-4941-a3b4-d3b8530682f3', '2025-03-21 16:48:35'),
(45, 37, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F37%2FCREACI%C3%93N%20DE%20CONTENIDO.jpg?alt=media&token=5eddc306-f751-4c6b-ac7c-cd6de0563f78', '2025-03-21 16:49:12'),
(46, 47, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F47%2FMU%C3%91ECAS%20DE%20TELA.jpg?alt=media&token=3a5d583b-589f-46db-b1a1-73047dc00942', '2025-03-21 16:49:27'),
(47, 49, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F49%2FBARBER%20SHOP.jpg?alt=media&token=dcff32b6-a985-4ddc-8cb2-7bd526608d53', '2025-03-21 16:52:48'),
(48, 46, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F46%2FPI%C3%91ATERIA.jpg?alt=media&token=9bdbd1e5-a40f-4e84-a0c2-8ea59a4a250a', '2025-03-21 16:56:15'),
(50, 57, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F57%2FTERAPIA%20EN%20CER%C3%81MICA.jpg?alt=media&token=40abc9f1-9579-42f7-97be-77f75e4e6996', '2025-03-28 16:07:35'),
(52, 58, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F58%2FCREACI%C3%93N%20DE%20CONTENIDO%202.jpg?alt=media&token=4e6f64e1-15b9-4d3b-bcba-f94de7dea3d3', '2025-03-28 20:31:34'),
(53, 69, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F69%2FLA%20BENDICI%C3%93N%20DEL%20CROCHET.jpeg?alt=media&token=cc2fdaac-8604-4de7-bf3a-1ce77ff93d93', '2025-04-23 17:40:23'),
(54, 23, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F23%2FMAQUILLAJE%2021%20MAYO.jpg?alt=media&token=ca6d43e9-b5b1-4b8e-98fd-f5cb35c2f103', '2025-05-02 23:34:45'),
(55, 48, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F48%2FDECOPAGE%2014%20DE%20MAYO.jpg?alt=media&token=a83e2999-f128-49bb-ab78-f235dd231231', '2025-05-02 23:36:22'),
(56, 55, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F55%2FPINTURA%20ACR%C3%8DLICA%2014%20MAYO.jpg?alt=media&token=9d7a1c67-b39f-4520-89d4-6d51e9ca6eef', '2025-05-02 23:36:54'),
(57, 72, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F72%2FINGL%C3%89S%20PRESENCIAL.jpg?alt=media&token=bcf6d99e-5886-4b8e-8df7-96e2be6f2016', '2025-05-02 23:37:34'),
(58, 73, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F73%2FINGL%C3%89S%20VIRTUAL.jpg?alt=media&token=77236445-3a47-4682-a306-e8c52733db97', '2025-05-02 23:37:53'),
(59, 75, 'https://firebasestorage.googleapis.com/v0/b/matriculasmujeres-e2535.appspot.com/o/imagenesCursos%2F75%2FMASAJE%20TERAP%C3%89UTICO%2015%20MAYO.jpg?alt=media&token=73e17cc4-1406-47c7-a358-bcdc08b78c75', '2025-05-02 23:38:18');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cursos`
--

CREATE TABLE `cursos` (
  `ID` int(11) NOT NULL,
  `NombreCurso` varchar(100) NOT NULL,
  `Descripcion` text DEFAULT NULL,
  `FechaInicio` date NOT NULL,
  `FechaFin` date NOT NULL,
  `Activo` bit(1) DEFAULT b'1',
  `Precio` decimal(10,2) NOT NULL,
  `PorcentajePagoProfe` int(11) NOT NULL DEFAULT 50,
  `cantidadCuotas` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `cursos`
--

INSERT INTO `cursos` (`ID`, `NombreCurso`, `Descripcion`, `FechaInicio`, `FechaFin`, `Activo`, `Precio`, `PorcentajePagoProfe`, `cantidadCuotas`) VALUES
(14, 'Almohadones, cojines y más - nivel pricipiante', 'Aprende a diseñar y confeccionar cojines de diferentes tamaños y formas, tubulares, cuadrados, rectangulares formas, hojas, luna, sol, corazón estrellas, nudos, flecos, silla, nuca, palletes capitoneados, de cama lumbares, navideños etc. Es un espacio creado para aprender la belleza de las formas y a la vez poder crear un emprendimiento.\nAprendes desde cero, desde como utilizar la máquina de coser.\nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(15, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'En este curso se amplía el conocimiento ya adquirido en el nivel básico, elaboras diseños de cojines tridimensionales, para exteriores e interiores, sillas de piscina y muebles de jardín, hamacas, mecedoras, poltronas, palletes etc.\nDebe tener conocimiento en utilizar la máquina de coser.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-05', '2025-06-28', b'1', 45000.00, 50, 3),
(16, 'Decoración con globos - Nivel Básico ', 'Un curso de decoración con globos básico está diseñado para enseñar las técnicas fundamentales para crear arreglos decorativos utilizando globos. En este curso, los participantes aprenderán a trabajar con diferentes tipos de globos (látex, foil, gigantes, entre otros) y dominarán técnicas como el inflado adecuado, la creación de estructuras sencillas (arcos, columnas, centros de mesa), y el uso de accesorios como cintas, pesos y decoraciones adicionales. Además, se enseñarán consejos para el manejo de los globos, seguridad en su uso y cómo combinar colores y tamaños para crear diseños armónicos. El curso suele ser práctico y dirigido tanto a principiantes como a aquellos que buscan iniciarse en el negocio de la decoración de eventos.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-05', '2025-06-28', b'1', 45000.00, 50, 3),
(17, 'Decoración con Globos - Nivel Avanzado ', 'El curso de decoración con globos nivel avanzado, está diseñado para quienes ya tienen conocimientos básicos de decoración con globos y desean perfeccionar sus habilidades, llevando sus creaciones a un nivel profesional. A través de clases prácticas y teóricas, aprenderás técnicas avanzadas para diseñar decoraciones únicas y espectaculares para todo tipo de eventos, emprendiendo en su propio negocio de decoración de eventos o mejorar sus habilidades para ofrecer servicios de alto nivel en el sector de la decoración.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-05', '2025-06-28', b'1', 45000.00, 50, 3),
(18, 'Costura y patronaje desde cero', 'En este curso las y los estudiantes inician desde cero, aprenden a tomar sus propias medidas y de otras personas. Luego trazan patrones a escala (pequeños), posteriormente trazan en papel, y luego trazan en la tela. Además, aprenden a manejar su propia máquina de coser. En este curso aprenderás a elaborar tus propias prendas y dejarás volar tu imaginación.\nNo incluye materiales. Monto no reembolsable.\n', '2025-03-31', '2025-06-26', b'1', 45000.00, 50, 3),
(19, 'Introducción a la cosmética natural', 'Evaluar los diferentes tipos de piel, crear extractos a partir de materia prima casera, para que tus cosméticos sean más económicos, cosmética facial: desmaquillante, geles limpiadores, limpiadores bifásicos, serum herbales, tónicos y cremas hidratantes, cosmética para spa y corporal : cremas, exfoliantes , aceites para masajes , sales y bombas efervescentes, perfumería : sólido y líquido más tratamientos a base de aromaterapia, cosmética capilar: champú, acondicionador, tratamiento capilar para la caspa, mascarillas de reconstrucción, tónicos, serum y protectores capilares, jabonería: ciencia de la saponificación, cosmética para barbería, higiene personal: desodorante, pasta dental , crema para hongos ,y talcos Maquillaje : delineador, encrespador, base , sombras, polvos translucidos y corrector.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-08', '2025-09-16', b'1', 90000.00, 50, 6),
(21, 'Cosmética natural – avanzado (solamente quienes llevaron los 3 meses, enero a marzo 2025)', 'En este curso aprenderás a crear y formular cosméticos como: cosmética masculina, higiene personal, cosmética capilar, jabonería.\nPara este nivel únicamente pueden matricular personas que llevaron introducción a la cosmética natural.\nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(22, 'Jabonería artesanal', 'En este curso de jabonería, aprenderás a elaborar jabones de manera profesional, dominando distintas técnicas y formulaciones. Desde la saponificación tradicional hasta el uso de tensoactivos y bases de glicerina, desarrollarás habilidades para crear productos de alta calidad, personalizados y con acabados únicos. ¿Qué aprenderás?  1. Saponificación en frío y caliente 2. Uso de tensoactivos 3. Uso correcto de Bases de glicerina 4. decoración y personalización 5. Formulación profesional.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(23, 'Maquillaje profesional ', '¡Convierte tu pasión por el maquillaje en un negocio exitoso! Inscríbete en nuestro curso de Maquillaje Profesional y aprende las técnicas más avanzadas para emprender en el mundo de la belleza. Descubre cómo dominar las tendencias, crear looks únicos y ofrecer servicios de alta calidad. Verás temas como maquillaje día noche, fotografía, novias hasta fantasía y efectos especiales. ¡No esperes más para empezar tu propio camino profesional!.\nNo incluye materiales. Monto no reembolsable.\n', '2025-05-21', '2025-10-29', b'1', 90000.00, 50, 6),
(25, 'Vestidos de baño', '¡Sumérgete en el mundo del estilo y la confianza, en nuestro curso de traje de baño, diseñado para todas las amantes de la moda y el verano, aprenderás a diseñar, confeccionar y personalizar trajes de baño que no solo resalten tu figura, sino también tu personalidad única! Te llevaremos a través de las últimas tendencias, técnicas de diseño y consejos prácticos, para que puedas combinar colores, texturas y patrones de manera creativa. Además, descubrirás la historia y evolución de estos icónicos atuendos de verano, mientras exploras cómo crear la pieza perfecta para ti o para compartir con el mundo. ¡No pierdas la oportunidad de transformar tu pasión por la moda en una experiencia inolvidable y lucir espectacular en la playa o la piscina!.\nDebe tener conocimiento en utilizar la máquina de coser.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-05', '2025-06-28', b'1', 45000.00, 50, 3),
(26, 'Costura básica desde cero - nivel intermedio ', 'La alta costura es un arte que fusiona la tradición y la innovación, donde cada puntada se convierte en una obra maestra. El corte y confección, meticuloso y preciso, da vida a prendas que no solo visten, sino que cuentan historias de elegancia y sofisticación, reflejando el talento de los artesanos que dan forma a la fantasía de la moda.\nDebe tener conocimiento en utilizar la máquina de coser.\nNo incluye materiales. Monto no reembolsable.\n', '2025-03-31', '2025-06-23', b'1', 45000.00, 50, 3),
(27, 'Costura básica desde cero - nivel básico', '¡Descubre el fascinante mundo de la costura en nuestro curso para principiantes! Aprende desde lo más básico, como elegir la tela adecuada y manejar la máquina de coser, hasta confeccionar tus propias prendas y accesorios con tus manos. No importa si nunca has tocado una aguja o si tienes un poco de experiencia, aquí te guiaremos paso a paso para que puedas crear proyectos únicos y personalizados. ¡Atrévete a dar rienda suelta a tu creatividad y transforma tus ideas en realidad!\nNo incluye materiales. Monto no reembolsable.\n', '2025-03-31', '2025-06-28', b'1', 45000.00, 50, 3),
(28, 'Bordado a mano', 'En este curso las alumnas lograrán elaborar bonitos caminos de mesas individuales cosmetiqueras cuadros con técnicas de bordado a mano por medio de los cuales pasarán un rato muy agradable además de adquirir estos lindos conocimientos. También sirve como una gran terapia. Se adquieren conocimientos en diferentes tipos de bordado a mano como punto de cruz, bordado español, cuadros en bordado, mexicano, guatemalteco, hardanger y otra variedad de bordados.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-03', '2025-06-26', b'1', 45000.00, 50, 3),
(31, 'Quilting', 'Este curso está diseñado para introducir a los participantes en el arte del quilting, desarrollando habilidades fundamentales y fomentando la creatividad. A lo largo del curso, los estudiantes aprenderán técnicas básicas de costura, creación de bloques de quilting, diseño y composición, acolchado y acabado. Además, se trabajará en un proyecto personal que permitirá aplicar lo aprendido y desarrollar un quilting único. Sin necesidad de experiencia previa, el curso ofrece una combinación de teoría y práctica, asegurando una experiencia formativa completa y enriquecedora en el mundo del quilting.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-02', '2025-06-25', b'1', 45000.00, 50, 3),
(32, 'Manicure profesional', '¿Te apasiona el cuidado de las uñas y te gustaría convertirlo en una carrera? ¡Nuestro curso de manicurista es la opción perfecta para ti! Te ofrecemos un programa completo que cubre todas las áreas esenciales del cuido de las uñas, aprenderás a realizar tratamientos en las uñas, cuido de cutículas, esmaltado, y aplicaciones de uñas artificiales.\nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-04', '2025-09-12', b'1', 90000.00, 50, 6),
(35, 'Canva - principiantes (virtual)', 'En este curso, aprenderá a utilizar una de las herramientas de diseño gráfico más populares y versátiles del momento. Ya sea un principiante o tenga cierta experiencia en el uso de la aplicación, este curso le ayudará a desarrollar habilidades creativas y a utilizar Canva y todas sus herramientas de manera eficiente para crear impresionantes diseños gráficos ya sea para uso digital o impreso.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-07', '2025-06-23', b'1', 45000.00, 50, 3),
(36, 'Canva - avanzado (presencial) - solamente quienes han llevado nivel principiantes.', 'Este curso intermedio de Canva está diseñado para usuarios que han cursado el nivel principiante o con experiencia demostrada que buscan llevar sus habilidades al siguiente nivel. Explora el diseño de videos, incorpora herramientas de inteligencia artificial y crea páginas web dinámicas, todo dentro de la plataforma Canva.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-12', '2025-06-28', b'1', 45000.00, 50, 3),
(37, 'Creación de contenido para redes sociales', 'Este curso ha sido creado especialmente para emprendedores que desean aprender a generar contenido para redes sociales. Adquirirá habilidades fundamentales en la creación de contenido y diseño gráfico, indispensables para sobresalir en las plataformas sociales. A lo largo del curso, obtendrá las herramientas y el conocimiento necesarios para brillar en el entorno digital.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-08', '2025-06-24', b'1', 45000.00, 50, 3),
(38, 'Portugués - principiantes (virtual)', 'En este curso el alumno tendrá la capacidad de entender conversaciones simples y preguntas cotidianas, capacidad para leer y comprender textos breves y sencillos. Tendrá la habilidad para presentarse, saludar y hacer preguntas básicas. ¡Anímese a aprender un idioma más!\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-04', '2025-09-19', b'1', 90000.00, 50, 6),
(39, 'Curso básico de panadería', 'Matricúlate en nuestro curso básico de pan, con este curso puedes emprender tu propio negocio, también es una excelente opción para todas las personas de deseen conocer el arte de hacer pan y llevarlo a las mesas de sus los hogares. Descubra con nosotros la magia de hacer pan.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-05', '2025-05-28', b'1', 45000.00, 50, 3),
(40, 'Alambrismo y Bisutería - Nivel Principiante', 'Introducir a los participantes en los conceptos básicos del alambrismo y la bisutería. Enseñar técnicas fundamentales para trabajar con alambre y gemas. Familiarizar a los participantes con las herramientas y materiales esenciales. Guiar a los participantes en la creación de sus propias piezas de bisutería. Fomentar la creatividad y el disfrute del proceso de creación. Crea tus Propios Tesoros. No incluye materiales. Monto no reembolsable.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(42, 'Panadería', '¡Aprende a hacer pan desde cero y conviértete en un experto en panadería! En este curso, exploraremos diferentes tipos de panes, incluyendo panes con masa madre, panes con levadura y el uso de diversas harinas para lograr texturas y sabores únicos. Este curso es 100% práctico y no necesitas experiencia previa. Ya sea que quieras hornear para tu familia o iniciar un negocio, aquí aprenderás todo lo necesario para hacer panes deliciosos y saludables. ¡Reserva tu cupo y empieza a hornear con confianza!.\n\nInstructora certificada por el INA. \nNo incluye materiales. Monto no reembolsable.\n', '2025-04-07', '2025-06-23', b'1', 45000.00, 50, 3),
(43, 'Pastelería – nivel #1', '¿Te encanta la pastelería, pero no sabes por dónde empezar? ¡Este curso es para ti! Aquí aprenderás desde cero las bases de la pastelería, con recetas y técnicas esenciales para que puedas hornear con confianza. No necesitas experiencia previa, solo ganas de aprender y disfrutar. Al finalizar, podrás sorprender a tu familia o incluso dar los primeros pasos para emprender en el mundo de la pastelería.\n\nInstructora certificada por el INA. \nNo incluye materiales. Monto no reembolsable.\n', '2025-04-07', '2025-06-23', b'1', 45000.00, 50, 3),
(44, 'Repostería', 'En este curso aprenderás a preparar una variedad de deliciosos postres tradicionales y modernos. No necesitas experiencia previa, solo ganas de aprender y disfrutar. En cada clase, te guiaremos paso a paso para que puedas dominar las técnicas y sorprender con tus creaciones. Ya sea para emprender o para consentir a tu familia, este curso te dará las bases para hornear con confianza. ¡Reserva tu cupo y descubre el placer de la repostería!.\n\nInstructora certificada por el INA. \nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-07', '2025-06-23', b'1', 45000.00, 50, 3),
(45, 'Pastelería – nivel #2', 'Si ya tienes experiencia en pastelería y quieres llevar tus habilidades al siguiente nivel, este curso es para ti. Aquí aprenderás técnicas avanzadas para perfeccionar tus preparaciones y lograr queques con un acabado profesional. Este curso es ideal para quienes ya manejan las bases de la pastelería y desean ampliar su conocimiento, ya sea para mejorar su emprendimiento o simplemente elevar la calidad de sus queques.\nInstructora certificada por el INA. \nNo incluye materiales. Monto no reembolsable.\n', '2025-04-08', '2025-06-24', b'1', 45000.00, 50, 3),
(46, 'Piñatería', 'En este curso aprenderás a montar y decorar distintos tipos de piñatas básicas, sabrás las herramientas y materiales para crear piñatas, cómo cortar y pegar el papel, cómo pasar un diseño a diferentes materiales como foam y estereofón para hacer piñatas de personajes, anímate a matricular y podrás hacer tus piñatas para actividades familiares o emprender.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-02', '2025-06-25', b'1', 45000.00, 50, 3),
(47, 'Muñecas de tela', 'En el curso de muñecas de tela usted será capaz al finalizar el mismo, de diseñar diferentes muñecas incluso desde un mismo patrón, ya que habrá adquirido conocimientos que le permitirán usar su creatividad. Es un curso apto para personas con conocimientos mínimos de costura. Si no sabes usar una máquina de coser, aquí te enseñare para que puedas avanzar en el curso.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-01', '2025-06-24', b'1', 45000.00, 50, 3),
(48, 'Decoupage y acabados', 'El decoupage es una técnica decorativa basada en la aplicación de recortes de papel, que se pegan en superficies como madera, vidrio, plástico, aluminio, tela, etc. Esta técnica se combina con otras como craquelado, decapado, relieves, esponjeado, etc. creando diseños más allá de un decoupage básico y así obtener un fino acabado en los proyectos. El uso se esta técnica decorativa en materiales de reciclaje es fantástica.\nNo incluye materiales. Monto no reembolsable.\n', '2025-05-14', '2025-08-01', b'1', 45000.00, 50, 3),
(49, 'Barber Shop', 'En este curso aprenderás todo lo que se relacionado con la barbería, cortes en tendencia, uso de peines, máquinas, tijeras, manejo de una barbería, costos, gastos, indumentaria. ¡Anímate a matricular!\nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-01', '2025-09-16', b'1', 90000.00, 50, 6),
(54, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'En este curso aprenderás todo lo que se relacionado con la barbería, cortes en tendencia, uso de peines, máquinas, tijeras, manejo de una barbería, costos, gastos, indumentaria. ¡Anímate a matricular!\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-07', '2025-06-23', b'1', 45000.00, 50, 3),
(55, 'Pintura Acrílica', ' ¿Alguna vez has sentido la necesidad de expresar tu creatividad y darle un toque personal a tu entorno? La pintura es una herramienta poderosa que nos permite conectar con nuestras emociones y transformar objetos cotidianos en obras de arte únicas. Este curso de pintura acrílica sobre diversas superficies te invita a descubrir el mundo del arte y a explorar tu potencial creativo. A través de una variedad de técnicas y materiales, aprenderás a transformar objetos de madera, tela, vidrio y otros materiales en piezas decorativas que te permitirán expresar tu individualidad. Pero los beneficios de la pintura van más allá de la creación artística. Numerosos estudios han demostrado que el arte, especialmente la pintura, tiene un impacto positivo en nuestra salud mental y física. La pintura ayuda a reducir el estrés, mejorar la concentración, aumentar la autoestima y fomentar la relajación. Al pintar, nuestro cerebro libera endorfinas, las llamadas \"hormonas de la felicidad\", que nos ayudan a sentirnos más felices y tranquilos. \nNo incluye materiales. Monto no rembolsable.\n', '2025-05-14', '2025-07-30', b'1', 45000.00, 50, 3),
(57, 'Terapia en cerámica', 'Ten tu propio espacio y aprende a pintar cerámica, donde cada color no es solo aprendizaje es tu espacio y terapia donde compartes con otras personas y crear piezas únicas, aprende a expandir tu creatividad y aprender varias técnicas para darle más realismo a tus creaciones, podrás aprender sobre brocha seca y otras técnicas. Instructora proporciona las piezas de cerámica para la venta. No incluye materiales. Monto no reembolsable.', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(58, 'Creación de contenido para redes sociales', 'Este curso ha sido creado especialmente para emprendedores que desean aprender a generar contenido para redes sociales. Adquirirá habilidades fundamentales en la creación de contenido y diseño gráfico, indispensables para sobresalir en las plataformas sociales. A lo largo del curso, obtendrá las herramientas y el conocimiento necesarios para brillar en el entorno digital.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-10', '2025-06-26', b'1', 45000.00, 50, 3),
(59, ' Cosmética natural - nivel avanzado', 'En este curso aprenderás a crear y formular cosméticos como: cosmética masculina, higiene personal, cosmética capilar, jabonería.\nPara este nivel únicamente pueden matricular personas que llevaron introducción a la cosmética natural.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(60, 'Masaje terapéutico - nivel avanzado', 'En este curso se aprenderá masaje circulatorio, deportivo y la aplicación de las maniobras aprendidas a población gestante y adulta mayor. El objetivo es aprender a analizar casos, para definir el topo de masaje adecuado de acuerdo con las necesidades del usuario\nEn este curso únicamente alumnos que llevaron masaje terapéutico nivel principiante.\nNo incluye materiales. Monto no reembolsable.\n\n', '2025-04-10', '2025-06-26', b'1', 45000.00, 50, 3),
(61, 'Maquillaje profesional nivel 2', '¡Convierte tu pasión por el maquillaje en un negocio exitoso! Inscríbete en nuestro curso de Maquillaje Profesional y aprende las técnicas más avanzadas para emprender en el mundo de la belleza. Descubre cómo dominar las tendencias, crear looks únicos y ofrecer servicios de alta calidad. Verás temas como maquillaje día noche, fotografía, novias hasta fantasía y efectos especiales. ¡No esperes más para empezar tu propio camino profesional!.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-19', '2025-07-12', b'1', 45000.00, 50, 3),
(62, 'Alambrismo y Bisutería - Nivel Intermedio', 'Este curso de alambrismo y bisutería de nivel intermedio está diseñado para aquellos que ya poseen conocimientos básicos en la creación de bisutería y desean llevar sus habilidades al siguiente nivel. Aprenderás técnicas más avanzadas de alambrismo, incluyendo el uso de alambres de diferentes calibres y materiales, la creación de diseños complejos con gemas y perlas, y el desarrollo de tu propio estilo único.\nEn este curso únicamente personas que llevaron nivel básico.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-04', '2025-06-27', b'1', 45000.00, 50, 3),
(63, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo martes 7 pm a 9 pm', 'Grupo martes 7 pm a 9 pm.\nPerfecciona las técnicas y habilidades que los profesionales de manicura deben dominar para ofrecer servicios de alta calidad. Aprenderás: Reparación y mantenimiento, uñas esculpidas, aplicación en gel, calcio, builder gel, polygel, uñas esculpidas.\nEn este curso únicamente pueden matricular quienes llevaron nivel básico.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-08', '2025-06-24', b'1', 45000.00, 50, 3),
(64, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'Grupo miércoles de 10:30 am a 12:30 pm.\nPerfecciona las técnicas y habilidades que los profesionales de manicura deben dominar para ofrecer servicios de alta calidad. Aprenderás: Reparación y mantenimiento, uñas esculpidas, aplicación en gel, calcio, builder gel, polygel, uñas esculpidas.\nEn este curso únicamente pueden matricular quienes llevaron nivel básico.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-09', '2025-06-25', b'1', 45000.00, 50, 3),
(65, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'Grupo viernes de 10:30 am a 12:30 pm.\nPerfecciona las técnicas y habilidades que los profesionales de manicura deben dominar para ofrecer servicios de alta calidad. Aprenderás: Reparación y mantenimiento, uñas esculpidas, aplicación en gel, calcio, builder gel, polygel, uñas esculpidas.\nEn este curso únicamente pueden matricular quienes llevaron nivel básico.\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-11', '2025-06-27', b'1', 45000.00, 50, 3),
(66, 'Costura básica desde cero - nivel intensivo', '¡Descubre el fascinante mundo de la costura en nuestro curso para principiantes! Aprende desde lo más básico, como elegir la tela adecuada y manejar la máquina de coser, hasta confeccionar tus propias prendas y accesorios con tus manos. No importa si nunca has tocado una aguja o si tienes un poco de experiencia, aquí te guiaremos paso a paso para que puedas crear proyectos únicos y personalizados. ¡Atrévete a dar rienda suelta a tu creatividad y transforma tus ideas en realidad!\nNo incluye materiales. Monto no reembolsable.\n', '2025-04-16', '2025-05-07', b'1', 15000.00, 50, 1),
(68, 'Vitro mosáico', 'El curso de vitromosaico es una experiencia inicial con el vidrio,  aprendiendo sobre la forma correcta de cortarlo,  desarrollando la habilidad para manejar el vidrio con cuidado pero sin miedo.\nSe inicia con cortes simples  en línea recta para formar cuadros y rectángulos  y pasar a formas orgánicas .De allí el concepto de mosaico pues es a base de pequeños vidrios cortados con su debidas herramientas aplicados uno a uno sobre el diseño y material escogido ya sea sobre superficie plana o tridimensional ( botellas o macetas por ejemplo).Además se aprenderá cómo pegarlos y el uso de fragua como parte de la proseso del vitromosaico. Es un curso inicial se usará el vidrio tanto simple, de colores y espejos para aprender a crear objetos decorativos y artesanales de acuerdo al interés del alumno. \nNo incluye materiales. Monto no reembolsable', '2025-04-26', '2025-06-24', b'1', 30000.00, 50, 2),
(69, 'La bendición del crochet', 'La bendición del crochet es un curso de tejido a una aguja, en el cual se aprenderá a crear diferentes artesanías como prendas de vestir, bolsos, bufandas, etc. Dando las herramientas de cómo se confecciona cada una de ellas, no importa si son principiantes o avanzados en dicha técnica, todas y todos pueden ingresar.\n¡Te esperamos!\nNo incluye materiales. Monto no rembolsable.\n', '2025-05-13', '2025-07-31', b'1', 45000.00, 50, 3),
(70, 'Corte básico y alta peluquería', '¿QUIERES FORMARTE COMO ESTILISTA PROFESIONAL? Iníciate en esta profesión con la formación necesaria para empezar tu carrera profesional. Este curso de Diseñador de estilo Profesional te capacitará para realizar técnicas de acondicionamiento del cabello y limpieza, corte, color, cambios de forma y técnicas avanzadas de decoloración y colorimetría. A QUIÉN VA DIRIGIDO El Curso Diseñador de estilo Profesional va dirigido a todas aquellas personas que quieren formarse como estilistas. Es un programa profesional teórico y práctico para quienes no tienen ningún conocimiento en estilismo y desean desarrollarse en el mundo de la peluquería y diseño de imagen. No incluye materiales. Monto no reembolsable', '2025-04-25', '2025-08-25', b'1', 60000.00, 50, 4),
(71, 'Inglés - profe Jacqueline Guzmán', 'Aprende un segundo idioma', '2025-04-28', '2025-10-06', b'1', 138000.00, 50, 6),
(72, 'Inglés - modalidad presencial', 'En este curso avanzarás desde lo básico hasta un nivel intermedio. Mejorarás tu vocabulario, pronunciación y gramática para comunicarte con confianza en situaciones reales como trabajo, viajes y compras. ¡Aprovecha más oportunidades laborales, culturales y personales!  Inscríbete hoy y transforma tu futuro.\nNo incluye materiales. Monto no reembolsable. Modalidad presencial.', '2025-05-15', '2025-10-23', b'1', 90000.00, 50, 6),
(73, 'Inglés - modalidad virtual', 'En este curso avanzarás desde lo básico hasta un nivel intermedio. Mejorarás tu vocabulario, pronunciación y gramática para comunicarte con confianza en situaciones reales como trabajo, viajes y compras. ¡Aprovecha más oportunidades laborales, culturales y personales!  Inscríbete hoy y transforma tu futuro.\nNo incluye materiales. Monto no reembolsable. Modalidad virtual', '2025-05-20', '2025-10-28', b'1', 90000.00, 50, 6),
(75, 'Masaje terapéutico', 'Este curso le brindará las bases para el aprendizaje del masaje occidental y sus respectivas maniobras, cuya aplicación se enfoca en objetivos como el alivio del dolor, la disminución del estrés y la prevención de lesiones. Durante el desarrollo del mismo, haremos una revisión básica de anatomía, y de conceptos generales que le permitirán aplicar los conocimientos adquiridos en diferentes grupos de población, incluyendo deportistas y adulto mayor.\nNo incluye materiales. Monto no reembolsable.\n', '2025-05-15', '2025-10-23', b'1', 90000.00, 50, 6);

--
-- Disparadores `cursos`
--
DELIMITER $$
CREATE TRIGGER `after_curso_delete` BEFORE DELETE ON `cursos` FOR EACH ROW BEGIN
	DELETE FROM cursoimagen where cursoID = OLD.ID;
    DELETE FROM matriculas WHERE IdCurso = OLD.ID; 
    DELETE FROM horarios_cursos
    WHERE IdCurso = OLD.ID; 
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `desercion`
--

CREATE TABLE `desercion` (
  `Id` int(11) NOT NULL,
  `Nombre` varchar(255) NOT NULL,
  `Cedula` varchar(50) NOT NULL,
  `Telefono` varchar(50) NOT NULL,
  `Correo` varchar(255) NOT NULL,
  `estadoPago` varchar(255) NOT NULL,
  `comprobante` varchar(255) DEFAULT '0',
  `formaPago` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `desercion`
--

INSERT INTO `desercion` (`Id`, `Nombre`, `Cedula`, `Telefono`, `Correo`, `estadoPago`, `comprobante`, `formaPago`) VALUES
(3, 'Laura Ugalde Calvo ', '113340646 ', '50672193934', 'lauugalde36@yahoo.com', 'Pendiente', '', NULL),
(4, 'Gabriela', '114540370', '50689636300', 'gabrielamatag@outlook.com', 'Pendiente', '2025031110283006166498822', NULL),
(5, 'Tamara Campos Rodriguez', '402700009', '50672703203', 'myrna.rodriguezn2@gmail.com', 'Pendiente', '', NULL),
(6, 'Myrna Rodriguez', '112340856', '50671241023', 'myrrn20@icloud.com', 'Pendiente', '', NULL),
(7, 'Patricia Suarez Jimenez ', '110800493', '50684080045', 'Patisuji80@gmail.com', 'Pendiente', '', NULL),
(8, 'Ligia Brenes Elizondo', '502200753', '50688102040', 'ligia.bre@gmail.com', 'Pendiente', 'FT250729312Y', NULL),
(9, 'Carolina Barquero Brenes ', '401850396', '50683346472', 'cvjbarquero@gmail.com', 'Pendiente', '92912697', NULL),
(10, 'Laura Moreno González ', '401870046', '50663604228', 'laumoreno237@gmail.com', 'Pendiente', '56924294', NULL),
(11, 'Guisela Murillo Cubero', '111630431', '50671300518', 'guiselamurillo12@gmail.com', 'Pendiente', '2025031810283006214781006', NULL),
(12, 'DAYANNA ', '117750879', '50688920041', 'calicalderon09@gmail.com', 'Pendiente', '23449451', NULL),
(13, 'Dayanna Garcia sanchez ', '23449451', '50688920041', 'calicalderon09@gmail.com', 'Pendiente', '23449451', NULL),
(24, 'Patricia Monge Bonilla', '105980500', '50683948747', 'Patricia2357@outlook.es', 'Pendiente', 'Becada ', NULL),
(25, 'Ligia Varela Muñoz ', '107370254 ', '50688057888', 'vivivarela68@gmail.com', 'Pendiente', 'BECADA ', NULL),
(26, 'Thaylin Zúñiga ', '604640538', '50684878814', 'zthay10@gmail.com', 'Pendiente', '55608362', NULL),
(27, 'Kelly Jexabell sequeira areas', '155802404327', '506', 'kelly.s.areas94@gmail.com', 'Pendiente', '20250302480383010395140783', NULL),
(28, 'Marianella Eduarte Rodríguez', '402040464', '506', 'nelaer221189@gmail.com', 'Pendiente', 'FT2508778X8F', NULL),
(29, 'Marianella Eduarte Rodríguez', '402040464', '50671526228', 'nelaer221189@gmail.com', 'Pendiente', '2832025', NULL),
(30, 'Jenny Beatriz Zeledón Zúñiga', '401770098', '50689161701', 'zeledonj09@yahoo.com', 'Pendiente', '98436505', 'SINPE Móvil'),
(31, 'Guadalupe concepción Hernández sandino ', '402300929', '506', 'lupitasandino41117@gmail.com', 'Pendiente', '10521057', NULL),
(32, 'Nayeli ', '402610041', '50663212216', 'nayelissoto049@gmail.com', 'Pendiente', 'Nayeli Soto ', NULL),
(33, 'Danna Paola Castillo Villalobos ', '1 1908 0280', '50687490111', 'dannacastillov2004@gmail.com', 'Pendiente', '2025033110283006289730621', NULL),
(34, 'Ana Jen Camacho Soto', '401070669', '50684416868', 'radiobarvacr@gmail.com', 'Pendiente', '', NULL),
(35, 'Xinia Arguedas vega', '2462507', '50671435344', 'xiniarguedas45@gmail.com', 'Pendiente', 'Becada', NULL),
(36, 'Maribel Berrocal Miranda', '401400554', '50688104611', 'mirandapalmamarielos@gmail.com', 'Pendiente', '2025040416183220542898083', NULL),
(37, 'Cecilia Dolores Arauz Robleto', '800460437', '50664790267', 'ceciarauz50@gmail.com', 'Pendiente', '04072881', NULL),
(38, 'Concepción de los angeles González galan ', '155818926626', '50672982489', 'concegonzalez85@gmail.com', 'Pendiente', '98667352', NULL),
(39, 'flor maria cascante Fernández', '50688820390', '50688820390', 'Fmcasf@gmail.com', 'Pendiente', '89847454', NULL),
(40, 'Magaly Solorzano Guerrero ', '701590004', '50687518714', 'maga.gata35@gmail.com', 'Pendiente', '17294056', NULL),
(41, 'Yensy Meza Cortés', '303400924', '50683083268', 'yensymeza22@gmail.com', 'Pendiente', '2025040710283006338147477', NULL),
(42, 'Pricilla Vargas González', '401960112', '506', 'prixi410@gmail.com', 'Pendiente', '', NULL),
(43, 'Tatiana María Arce Ramirez ', '402100180 ', '50670282748', 'arcem9269@gmail.com', 'Pendiente', '70282748 ', NULL),
(44, 'Erika Isabel Lopez Mejia', '155813950517', '50688617062', 'lopezmejiaerika8@gmail.com', 'Pendiente', '11172869', NULL),
(45, 'Martha León López ', '14740370', '50670815196', 'marthaleolop@gmail.com', 'Pendiente', '50090365', NULL),
(46, 'Yinyer morales Sibaja', '111970241', '50664837504', 'gingerms1984@gmail.com', 'Pendiente', '1242948193', NULL),
(47, 'Katthy Rodríguez Madrigal', '109890117', '50660331077', 'katthyarodriguezcr@hotmail.com', 'Pendiente', '1234', NULL),
(48, 'Angelita Valerio Sánchez', '108300643', '50686132525', 'avalerio48@hotmail.com', 'Pendiente', '', NULL),
(49, 'Mónica Hernández Paniagua ', '115830332 ', '50685589568', 'hernandezmoni22@hotmail.com', 'Pendiente', '28759405', NULL),
(50, 'María Fernanada Urra Sánchez', '112180758', '50685655826', 'mariger_urra@hotmail.com', 'Pendiente', '', NULL),
(51, 'Yamileth Arce Barquero', '401380433', '50683391283', 'yarcebarquero@gmail.com', 'Pendiente', 'BECADA', NULL),
(52, 'Abril Gabriela Vindas Castro', '402550825', '50672868191', 'avindas2014@gmail.com', 'Pendiente', '92358421', NULL),
(53, 'Abril Gabriela Vindas Castro', '402550825', '50672868191', 'avindas2014@gmail.com', 'Pendiente', '', NULL),
(54, 'Yendry Díaz Valverde', '701670581', '50663562510', 'yendrydiazv@gmail.com', 'Pendiente', '52353242', NULL),
(55, 'Ana Patricia Monge Bonilla ', '105980500', '50683948747', 'Patricia2357@outlook.es', 'Pendiente', 'Becada ', NULL),
(56, 'Yensy Meza Cortés', '303400924', '50683083268', 'yensymeza22@gmail,com', 'Pendiente', '', NULL),
(57, 'Cinthya Hypatia Gutiérrez Abarca ', '801090982', '50664516749', 'cinlayj2@gmail.com', 'Pendiente', '2025010310283005778048720', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horarios_cursos`
--

CREATE TABLE `horarios_cursos` (
  `ID` int(11) NOT NULL,
  `DiaSemana` enum('Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo') NOT NULL,
  `HoraInicio` time NOT NULL,
  `HoraFin` time NOT NULL,
  `IdCurso` int(11) NOT NULL,
  `IdProfesor` int(11) NOT NULL,
  `cupo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `horarios_cursos`
--

INSERT INTO `horarios_cursos` (`ID`, `DiaSemana`, `HoraInicio`, `HoraFin`, `IdCurso`, `IdProfesor`, `cupo`) VALUES
(13, 'Viernes', '08:00:00', '10:00:00', 14, 9, 10),
(14, 'Sábado', '08:00:00', '10:00:00', 15, 9, 10),
(15, 'Sábado', '08:00:00', '10:00:00', 16, 8, 7),
(16, 'Sábado', '10:30:00', '12:30:00', 17, 8, 7),
(17, 'Lunes', '08:00:00', '10:00:00', 18, 11, 10),
(18, 'Lunes', '10:30:00', '12:30:00', 18, 11, 10),
(19, 'Jueves', '08:00:00', '10:00:00', 18, 11, 10),
(20, 'Jueves', '10:30:00', '12:30:00', 18, 11, 10),
(21, 'Martes', '13:00:00', '15:00:00', 19, 12, 15),
(22, 'Viernes', '13:00:00', '15:00:00', 21, 12, 15),
(23, 'Viernes', '09:00:00', '11:00:00', 22, 12, 15),
(24, 'Miércoles', '16:00:00', '19:00:00', 23, 14, 15),
(25, 'Sábado', '16:00:00', '19:00:00', 23, 14, 15),
(28, 'Sábado', '15:30:00', '17:30:00', 25, 6, 10),
(29, 'Lunes', '15:30:00', '17:30:00', 26, 6, 10),
(30, 'Lunes', '18:00:00', '20:00:00', 27, 6, 10),
(31, 'Sábado', '13:00:00', '15:00:00', 27, 6, 10),
(32, 'Jueves', '09:30:00', '11:30:00', 28, 15, 10),
(35, 'Miércoles', '08:00:00', '10:00:00', 31, 17, 10),
(36, 'Miércoles', '10:30:00', '12:30:00', 31, 17, 10),
(37, 'Viernes', '08:00:00', '10:00:00', 32, 18, 15),
(40, 'Lunes', '19:00:00', '20:30:00', 35, 19, 8),
(41, 'Sábado', '10:30:00', '12:30:00', 36, 19, 10),
(42, 'Martes', '18:00:00', '20:00:00', 37, 19, 8),
(43, 'Viernes', '19:00:00', '20:30:00', 38, 1, 12),
(44, 'Sábado', '13:00:00', '16:00:00', 39, 23, 10),
(45, 'Viernes', '16:00:00', '18:00:00', 40, 20, 15),
(47, 'Lunes', '08:00:00', '11:30:00', 42, 21, 15),
(48, 'Lunes', '13:00:00', '16:30:00', 43, 21, 15),
(49, 'Lunes', '17:00:00', '20:30:00', 44, 21, 15),
(50, 'Martes', '08:00:00', '11:30:00', 45, 21, 15),
(51, 'Miércoles', '13:00:00', '16:00:00', 46, 22, 10),
(52, 'Martes', '13:00:00', '15:00:00', 47, 24, 15),
(53, 'Viernes', '10:30:00', '12:30:00', 48, 3, 10),
(54, 'Martes', '18:00:00', '20:00:00', 49, 2, 10),
(60, 'Lunes', '19:00:00', '21:00:00', 54, 2, 6),
(61, 'Miércoles', '16:00:00', '18:00:00', 55, 5, 15),
(63, 'Viernes', '16:30:00', '18:30:00', 57, 25, 10),
(64, 'Jueves', '18:00:00', '20:00:00', 58, 19, 10),
(65, 'Jueves', '08:00:00', '10:00:00', 60, 16, 7),
(66, 'Sábado', '13:00:00', '16:00:00', 61, 14, 10),
(67, 'Miércoles', '13:00:00', '16:00:00', 61, 14, 3),
(68, 'Viernes', '13:00:00', '15:00:00', 62, 20, 7),
(69, 'Martes', '19:00:00', '21:00:00', 63, 18, 6),
(70, 'Miércoles', '10:30:00', '12:30:00', 64, 18, 15),
(71, 'Viernes', '10:30:00', '12:30:00', 65, 18, 15),
(72, 'Miércoles', '18:00:00', '20:00:00', 66, 6, 6),
(74, 'Sábado', '10:30:00', '12:30:00', 68, 7, 3),
(75, 'Martes', '16:30:00', '18:30:00', 69, 28, 15),
(76, 'Lunes', '10:30:00', '13:30:00', 70, 4, 5),
(77, 'Lunes', '08:00:00', '10:00:00', 71, 13, 3),
(78, 'Jueves', '18:00:00', '20:00:00', 72, 27, 15),
(79, 'Martes', '17:00:00', '19:00:00', 73, 27, 15),
(80, 'Jueves', '10:30:00', '12:30:00', 75, 16, 10),
(82, 'Miércoles', '10:30:00', '12:30:00', 48, 3, 10);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `listapagosprofesor`
--

CREATE TABLE `listapagosprofesor` (
  `idPago` int(11) NOT NULL,
  `NombreProfesor` varchar(100) NOT NULL,
  `NombreCurso` varchar(45) NOT NULL,
  `idProfesor` int(11) NOT NULL,
  `idCurso` int(11) NOT NULL,
  `CedulaProfesor` varchar(45) NOT NULL,
  `TelefonoProfesor` varchar(45) NOT NULL,
  `CorreoProfesor` varchar(45) NOT NULL,
  `TotalPagar` decimal(10,2) NOT NULL DEFAULT 0.00,
  `EstadoPago` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `listapagosprofesor`
--

INSERT INTO `listapagosprofesor` (`idPago`, `NombreProfesor`, `NombreCurso`, `idProfesor`, `idCurso`, `CedulaProfesor`, `TelefonoProfesor`, `CorreoProfesor`, `TotalPagar`, `EstadoPago`) VALUES
(170, 'Kimberly Solís Gamazo', 'Corte básico y alta peluquería', 4, 67, '112540960', '64010034', 'kimberly.solis.gamazo@gmail.com', 1875.00, 0),
(171, 'Ligia Varela Víquez', 'Vestidos de baño', 6, 25, '107370254', '88057888', 'vivivarela68@gmail.com', 30000.00, 0),
(172, 'Ligia Varela Víquez', 'Costura básica desde cero - nivel intermedio ', 6, 26, '107370254', '88057888', 'vivivarela68@gmail.com', 60000.00, 0),
(173, 'Ligia Varela Víquez', 'Costura básica desde cero - nivel básico', 6, 27, '107370254', '88057888', 'vivivarela68@gmail.com', 300000.00, 0),
(174, 'Ligia Varela Víquez', 'Costura básica desde cero - nivel intensivo', 6, 66, '107370254', '88057888', 'vivivarela68@gmail.com', 22500.00, 0),
(175, 'Sadie Alvarado Miranda', 'Vitro mosáico', 7, 68, '401380422', '87366578', 'sadiealvaradomiranda04@gmail.com', 15000.00, 0),
(176, 'Ariana Álvarez Arguedas', 'Decoración con globos - Nivel Básico ', 8, 16, '112930816', '88741010', 'ariana31086@hotmail.com', 45000.00, 0),
(177, 'Ariana Álvarez Arguedas', 'Decoración con Globos - Nivel Avanzado ', 8, 17, '112930816', '88741010', 'ariana31086@hotmail.com', 52500.00, 0),
(178, 'Ana Patricia Monge Bonilla', 'Almohadones, cojines y más - nivel pricipiant', 9, 14, '105980500', '83948747', 'patricia2357@outlook.es', 7500.00, 0),
(179, 'Ana Patricia Monge Bonilla', 'Almohadones, cojines y más – Nivel intermedio', 9, 15, '105980500', '83948747', 'patricia2357@outlook.es', 30000.00, 0),
(180, 'Dorcas Pérez Cisneros', 'Costura y patronaje desde cero', 11, 18, '900780944', '86197534', 'yayita61.25@gmail.com', 60000.00, 0),
(181, 'Kendry González Chanto', 'Introducción a la cosmética natural', 12, 19, '118240258', '71209131', 'kendrygonzalezchacon@gmail.com', 82500.00, 0),
(182, 'Kendry González Chanto', 'Cosmética natural – avanzado (solamente quien', 12, 21, '118240258', '71209131', 'kendrygonzalezchacon@gmail.com', 30000.00, 0),
(183, 'Kendry González Chanto', 'Jabonería artesanal', 12, 22, '118240258', '71209131', 'kendrygonzalezchacon@gmail.com', 60000.00, 0),
(184, 'Leidy Céspedes Murillo', 'Maquillaje profesional ', 14, 23, '401970473', '83563091', 'cespedesmu01@hotmail.com', 105000.00, 0),
(185, 'Leidy Céspedes Murillo', 'Maquillaje profesional nivel 2', 14, 61, '401970473', '83563091', 'cespedesmu01@hotmail.com', 45000.00, 0),
(186, 'Lizbeth Víquez Salas', 'Bordado a mano', 15, 28, '401630071', '87489015', 'l_viquez12@hotmail.com', 30000.00, 0),
(187, 'Luisa Gutiérrez Pardo', 'Masaje terapéutico - nivel avanzado', 16, 60, '117002187304', '83506991', 'luisagutierrezpardo@hotmail.com', 37500.00, 0),
(188, 'Marielos Artavia Fernández', 'Quilting', 17, 31, '302800134', '84384390', 'fernandezartavia65@gmail.com', 45000.00, 0),
(189, 'Melissa Solano Rodríguez', 'Manicure profesional', 18, 32, '112920450', '71381440', 'melissasolano8628@gmail.com', 82500.00, 0),
(190, 'Melissa Solano Rodríguez', 'Manicure profesional - solamente quienes llev', 18, 63, '112920450', '71381440', 'melissasolano8628@gmail.com', 15000.00, 0),
(191, 'Melissa Solano Rodríguez', 'Manicure profesional - solamente quienes llev', 18, 64, '112920450', '71381440', 'melissasolano8628@gmail.com', 37500.00, 0),
(192, 'Melissa Solano Rodríguez', 'Manicure profesional - solamente quienes llev', 18, 65, '112920450', '71381440', 'melissasolano8628@gmail.com', 7500.00, 0),
(193, 'Michael Quesada Fernández', 'Canva - principiantes (virtual)', 19, 35, '112250473', '72820107', 'metanoicacs07@gmail.com', 30000.00, 0),
(194, 'Michael Quesada Fernández', 'Creación de contenido para redes sociales', 19, 37, '112250473', '72820107', 'metanoicacs07@gmail.com', 60000.00, 0),
(195, 'Selphine Royal Dunn', 'Alambrismo y Bisutería - Nivel Principiante', 20, 40, '113070525', '89912008', 'selari2602@gmail.com', 52500.00, 0),
(196, 'Selphine Royal Dunn', 'Alambrismo y Bisutería - Nivel Intermedio', 20, 62, '113070525', '89912008', 'selari2602@gmail.com', 30000.00, 0),
(197, 'Silvia Vargas Hernández', 'Panadería', 21, 42, '401860689', '85473391', 'mivanpri24@gmail.com', 37500.00, 0),
(198, 'Silvia Vargas Hernández', 'Pastelería – nivel #1', 21, 43, '401860689', '85473391', 'mivanpri24@gmail.com', 75000.00, 0),
(199, 'Silvia Vargas Hernández', 'Repostería', 21, 44, '401860689', '85473391', 'mivanpri24@gmail.com', 105000.00, 0),
(200, 'Silvia Vargas Hernández', 'Pastelería – nivel #2', 21, 45, '401860689', '85473391', 'mivanpri24@gmail.com', 97500.00, 0),
(201, 'Rocío Salas Cortés', 'Curso básico de panadería', 23, 39, '401480051', '83780023', 'rocio.salas.cortes@icloud.com', 7500.00, 0),
(202, 'Raquel Campos Chavarría', 'Portugués - principiantes (virtual)', 1, 38, '401910222', '63634327', 'reunice.cha@gmail.com', 15000.00, 0),
(203, 'Kimberly Solís Gamazo', 'Corte básico y alta peluquería', 4, 70, '112540960', '64010034', 'kimberly.solis.gamazo@gmail.com', 22500.00, 0),
(204, 'Jacqueline Guzmán Arguedas ', 'Inglés - profe Jacqueline Guzmán', 13, 71, '401370591', '89375828', 'bjaguar64@gmail.com', 23000.00, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `matriculas`
--

CREATE TABLE `matriculas` (
  `Id` int(11) NOT NULL,
  `Nombre` varchar(100) NOT NULL,
  `Cedula` varchar(50) NOT NULL,
  `Telefono` varchar(15) NOT NULL,
  `Correo` varchar(100) NOT NULL,
  `estadoPago` varchar(45) NOT NULL,
  `comprobante` varchar(100) NOT NULL,
  `IdCurso` int(11) DEFAULT NULL,
  `IdHorario` int(11) DEFAULT NULL,
  `formaPago` varchar(45) DEFAULT NULL,
  `desercion` int(11) DEFAULT 0,
  `cuotasPendientes` int(11) DEFAULT 0,
  `activa` tinyint(1) NOT NULL DEFAULT 1,
  `pendientePago` tinyint(1) NOT NULL DEFAULT 1,
  `fechaCreacion` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `matriculas`
--

INSERT INTO `matriculas` (`Id`, `Nombre`, `Cedula`, `Telefono`, `Correo`, `estadoPago`, `comprobante`, `IdCurso`, `IdHorario`, `formaPago`, `desercion`, `cuotasPendientes`, `activa`, `pendientePago`, `fechaCreacion`) VALUES
(11, 'Elizabeth Campos Hernández ', '108160250', '50683436720', 'camposeli@hotmail.es', 'Pendiente', '23117597', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(12, 'Ana Porras Segura', '110210125', '50685974692', 'anacripo@hotmail.com', 'Pendiente', '247237772', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(13, 'Carmen Murillo Espinoza', '20482781', '50689873903', 'carmenmurilloespinoza@gmail.com', 'Pendiente', '20250307814830000600298728', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(14, 'Guadalupe Murillo Espinoza', '2473966', '50685068415', 'murillog972@gmail.com', 'Pendiente', '20250307814830000600299998', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(20, 'Catalina Sánchez Sánchez ', '206690166', '50683345869', 'cata23ss@hotmail.com', 'Pendiente', '93858099', 43, 48, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(21, 'Carla Hernández Solís', '602470850', '50689325062', 'karlahs1872@gmail.com', 'Pendiente', '2025030710283006142571381', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(26, 'Patricia Bermudez Ramírez ', '107700528', '50688472954', 'patribr14@gmail.com', 'Pendiente', '2025030780383010388743050', 23, 24, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(28, 'Milena Mendoza Valenciano', '701100837', '50689932919', 'mmendoza@una.ac.cr', 'Pendiente', '94210067', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(30, 'María de los Ángeles Ríos Obando', '1-1116-0992 ', '50671036841', 'anais2409@gmail.com', 'Pendiente', '55887035', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(36, 'Carla Hernández Solis', '6247850', '50689325062', 'karlahs1872@gmail.com', 'Pendiente', '29082076', 37, 42, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(37, 'Valentina gabriela Morales Sánchez ', '402730546', '50684490254', 'valentinagabriela1406@gmail.com', 'Pendiente', '30860478', 40, 45, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(38, 'Marianela Cerdas Gómez ', '402070781', '50685501226', 'nelac0809@gmail.com', 'Pendiente', '94017511', 16, 15, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(39, 'Jesenia Torres Vargas', '117870417', '50686264451', 'jestorres03@hotmail.com', 'Pendiente', '93960257', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(41, 'Miriam Salas Arce ', '108410277', '50672134027', 'mirsalasa@gmail.com', 'Pendiente', '93986425', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(42, 'Viviana Cerdas Gómez ', '207450030', '50689778594', 'vivianacerdasgomez@gmail.com', 'Pendiente', '2025030715283006429537559', 16, 15, NULL, 0, 3, 1, 1, '2025-03-23 16:57:08'),
(49, 'Ana Porras Segura', '110210125', '50685974692', 'anacripo@hotmail.com', 'Pendiente', '24724237', 37, 42, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(50, 'Catalina Sánchez Sánchez ', '206690166', '50683345869', 'cata23ss@hotmail.com', 'Pendiente', '93862872', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(51, 'Krysta Nicole Navarro Carvajal', '117640290', '50687842662', 'nicolnc02@gmail.com', 'Pendiente', '2025030710283006144377155', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(52, 'Irene Villalobos León', '402110502', '50689158623', 'ire_villalobos_18@hotmail.com', 'Pendiente', '94329402', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(53, 'Marjorie Bonilla Benavides ', '1-0621-0927 ', '50683496850', 'yuriboni64@gmail.com', 'Pendiente', '2025030782183010347600371', 27, 30, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(54, 'Elizabeth Vargas López ', '104520944', '50661148230', 'marieliza317@gmail.com', 'Pendiente', 'FT250666LXFQ', 27, 30, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(55, 'Dayanna Aguilar Brenes ', '603050700', '50688273519', 'dayannaa3@gmail.com', 'Pendiente', '2025030710283006145415484', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(56, 'Marian Carillo Valverde ', '111560465', '50670155093', 'valerysala07@gmail.com', 'Pendiente', '32933781', 43, 48, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(57, 'Paola Vargas', '109600558', '506', 'jpavazu@gmail.com', 'Pendiente', 'BECADA', 17, 16, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(58, 'Diana Rojas Alpízar ', '205050645', '50670872884', 'diana121075@hotmail.com', 'Pendiente', '2025030815283006437231217', 22, 23, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(59, 'Tiffany Ramírez Leitón ', '119810016', '50686881003', 'tiffarl10@gmail.com', 'Pendiente', '50966157', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(60, 'José Mario Valerio Berrocal ', '401940089', '50684553578', 'jvalerio419@gmail.com', 'Pendiente', '98764280', 42, 47, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(61, 'Marcela Arce Espinoza', '108060527', '50686677561', 'marcearceespinoza@gmail.com', 'Pendiente', '55028719', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(62, 'Patricia Ramírez Rimolo ', '108270565 ', '50670395794', 'masiescara98@gmail.com', 'Pendiente', '2025031010283006162174131', 16, 15, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(63, 'Masiel Escalante Ramírez ', '402370817', '50663786607', 'masiescara98@gmail.com', 'Pendiente', '2025031015283006451844391', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(64, 'Vanessa Rodríguez Serrano ', '303750678', '50661481859', 'vrs3981@hotmail.com', 'Pendiente', 'BECADA', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(65, 'Kerlyn Fernández Obando ', '112860687', '50683193219', 'kerlyn_07@yahoo.es', 'Pendiente', '52303749', 23, 25, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(66, 'Angelica Ramirez', '304410397', '50683032314', 'arami13@gmail.com', 'Pendiente', '20250310102830061638722966', 27, 30, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(67, 'Maria de Guadalupe Estrada Medrano', 'Pasaporte N08039338', '50672354223', 'ing.guadalupe.estrada@gmail.com', 'Pendiente', 'BCR REFERENCIA 2025031015283006454091911', 27, 30, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(69, 'Karen Camacho Valerio', '401840724', '50688103763', 'kata1308@gmail.com', 'Pendiente', 'FT2507087TS9', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(71, 'Greidy Hernández Esteban ', '113620824', '50670119590', 'greidy.hernandez@hotmail.com', 'Pendiente', '2025040880383010400954813', 45, 50, NULL, 0, 1, 1, 1, '2025-03-23 16:57:08'),
(72, 'Gabriela Mata Gamboa ', '114540360', '50689636300', 'gabrielamatag@outlook.com', 'Pendiente', '2025031110283006166498822', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(73, 'Valeria campos lobo', '402210923', '50672041477', 'valecl2693@gmail.com', 'Pendiente', '2025031210283006170323281', 43, 48, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(74, 'Elodia Hernandez Vargas ', '401440460 ', '50687830596', 'elo.her@hotmail.es', 'Pendiente', '60238490', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(75, 'Doris Carolina Rodríguez Ramírez', '112780769', '50683467785', 'dorys18@gmail.com', 'Pendiente', '56858218', 23, 25, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(76, 'Karen Herrera Sandi', '117830143', '50684158568', 'kherrera0520@gmail.com', 'Pendiente', '91266642', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(79, 'Sharon Gustavina Arce ', '402870905', '50685574353', 'alelobo4060@gmail.com', 'Pendiente', '2025031310283006176865521', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(82, 'Carolina Barquero Brenes ', '401850396', '50683346472', 'cvjbarquero@gmail.com', 'Pendiente', '92912697', 40, 45, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(83, 'Catalina Jiménez Ramírez', '113250320', '50684984125', 'catalinajimenezr13@gmail.com', 'Pendiente', '6178816507', 19, 21, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(84, 'Mercedes Manzanares Barahona', '800770707', '50687922465', 'william.Bermudez.ramirez@gmail.com', 'Pendiente', '93775791', 43, 48, NULL, 0, 1, 1, 1, '2025-03-23 16:57:08'),
(85, 'Ligia Brenes Elizondo', '502200753', '50688102040', 'ligia.bre@gmail.com', 'Pendiente', '55366055', 40, 45, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(86, 'Dafnaly Mitre Hernandez', '702680854', '50664181317', 'dafmh1228@gmail.com', 'Pendiente', '2025031410283006182966558', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(87, 'Marycruz Ocampo Aguilar ', '108080245', '50688388581', 'maricruzocampo@yahoo.es', 'Pendiente', '93830653', 43, 48, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(88, 'Norma Moreira Chaves', '105740788', '50688304982', 'nmoreirach@gmail.com', 'Pendiente', 'Ft25073BVY6N', 45, 50, NULL, 0, 1, 1, 1, '2025-03-23 16:57:08'),
(89, 'Flor María Vega Rojas ', '108950861', '50660062099', 'florvega010@gmail.com', 'Pendiente', '2025031410283006185067381', 22, 23, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(90, 'Karol Chinchilla Barrientos', '109900292', '50687053610', 'karolchiba40@gmail.com', 'Pendiente', '2025031410283006185431786', 27, 31, NULL, 0, 1, 1, 1, '2025-03-23 16:57:08'),
(91, 'Laura Moreno González ', '401870945', '50663604228', 'laumoreno237@gmail.com', 'Pendiente', '50127044', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(92, 'Lidia Ramírez Bogantes ', '401950754 ', '50688792586', 'lidiramiboga25@hotmail.com', 'Pendiente', '2025031580383010392100985', 37, 42, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(94, 'Concepción de los angeles González galan ', '155818926626', '50672982489', 'concegonzalez85@gmail.com', 'Pendiente', '98667352', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(95, 'Anayanci Hernandez ', '401880312', '50688820808', 'yanci0723@gmail.com', 'Pendiente', '99381400', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(96, 'Silvia Ruiz Hernandez ', '106330197', '50683547496', 'majorh_123@outlook.com', 'Pendiente', '99579184', 28, 32, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(97, 'Carmen Salazar Torres', '402340174', '50686918249', 'cbeatriz1797@gmail.com', 'Pendiente', '2025031710283006206474137', 27, 31, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(99, 'Maricel Rodriguez Serrano ', '303330605 ', '50686195081', 'maricel111974@gmail.com', 'Pendiente', 'BECADA', 22, 23, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(101, 'Natalie Ramos Campos ', '4 0282 0851', '50662912560', 'vivi.camposh@gmail.com', 'Pendiente', '90349978', 49, 54, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(102, 'Isabel Cristina Rosales Chavarría ', '108390723', '50688238231', 'isabelrosales2910@hotmail.com', 'Pendiente', '2025031810283006210948662', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(103, 'Marjorie Ruiz Hernandez ', '107510249', '50683547496', 'majorh_123@outlook.com', 'Pendiente', '91165854', 28, 32, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(104, 'Alanis Camila Arce Lobo ', '402760839', '50660649951', 'arcecamila730@gmail.com', 'Pendiente', '53915764', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(107, 'Guisela Murillo Cubero', '111620431', '50671300518', 'guiselamurillo12@gmail.com', 'Pendiente', '2025031810283006214781006', 49, 54, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(108, 'Ana Isabel Mora Romero', '10710-0406.', '50689165559', 'anita60mr@gmail.com', 'Pendiente', ' Referencia 2025031915183010556767637.', 19, 21, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(109, 'Katherine Siles Madrigal', '110590914', '50683119972', 'kathysilesm20@gmail.com', 'Pendiente', '92875642', 16, 15, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(110, 'Karen García Quirós ', '118720579', '50672416747', 'karengarciaquiross@gmail.com', 'Pendiente', '15901511', 16, 15, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(111, 'Ingrid Gutiérrez Rojas', '701910282 ', '50688800148', 'ingridgr2022@gmail.com', 'Pendiente', '92892374', 42, 47, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(112, 'Dayanna García Sánchez ', '0117750879', '50688920041', 'calicalderon09@gmail.com', 'Pendiente', '57799713', 23, 25, NULL, 0, 4, 1, 1, '2025-03-23 16:57:08'),
(113, 'Brittany Sanchez ', '4 02690283', '50662486415', 'brisj10909m@gmail.com', 'Pendiente', '24949541', 32, 37, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(117, 'Laura Ugalde Calvo ', '113340646 ', '50672193934', 'lauugalde36@yahoo.com', 'Pendiente', '50956696', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(118, 'Hellen Alvarado Mora ', '11005230', '50660294024', 'hellenalvarado.528@gmail.com', 'Pendiente', '17476435', 45, 50, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(120, 'Katthya Trejos Zamora', '401480554 ', '50688831919', 'trejoskz68@gmail.com', 'Pendiente', '94553375', 43, 48, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(121, 'Xinia Arguedas Vega ', '2 462 507', '50671435344', 'xiniarguedas45@gmail.com', 'Pendiente', 'dqwd', 15, 14, NULL, 0, 0, 1, 1, '2025-03-23 16:57:08'),
(122, 'Ana Leticia Chaves Ramírez ', '401480834', '50687292738', 'alei353@hotmail.com', 'Pendiente', 'Becada', 25, 28, NULL, 0, 1, 1, 1, '2025-03-23 16:57:08'),
(123, 'Wendy Lorena raudales moncada ', '801270603 ', '50685765304', 'wendyraudalesm@gmail.com', 'Pendiente', '94835880', 44, 49, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(124, 'Mariela Rojas Calderón ', '113830662', '50687681082', 'marie2489@gmail.com', 'Pendiente', '59478704', 38, 43, NULL, 0, 2, 1, 1, '2025-03-23 16:57:08'),
(125, 'Hazel Argüello Guerrero', '604600552', '50685862323', 'hazelarguelloguerrero27@gmail.com', 'Pendiente', '2025032110283006230046602', 38, 43, NULL, 0, 5, 1, 1, '2025-03-23 16:57:08'),
(129, 'Jessica Montero Morales', '106790295', '50660407375', 'jemonteromorales@gmail.com', 'Pendiente', '53698413', 35, 40, NULL, 0, 2, 1, 1, '2025-03-24 17:16:31'),
(130, 'Jessica Montero Morales ', '106790295', '50660407375', 'jemonteromorales@gmail.com', 'Pendiente', '53694326', 37, 42, NULL, 0, 2, 1, 1, '2025-03-24 17:18:14'),
(134, 'Andrea León López ', '115400953', '50672082849', 'andylopstar15@gmail.com', 'Pendiente', '50035716', 37, 42, NULL, 0, 2, 1, 1, '2025-03-24 12:50:07'),
(135, 'Mónica Albonico Araya', '107160047', '50689824740', 'monicalbonico@gmail.com', 'Pendiente', '2025032410283006247156837', 37, 42, NULL, 0, 2, 1, 1, '2025-03-24 12:52:24'),
(138, 'Yancy Villalobos ', '401750832 ', '50685966794', 'yancyvch21@gmail.com', 'Pendiente', '50740403', 35, 40, NULL, 0, 2, 1, 1, '2025-03-24 14:35:02'),
(140, 'Yendry Miranda D', '111490268', '50660509008', 'agosto2482@gmail.com', 'Pendiente', 'BAC 2025032410283006247806643', 27, 30, NULL, 0, 2, 1, 1, '2025-03-24 14:45:09'),
(141, 'Pamela Quiros', '116680534', '50660761584', 'pamelaquiros9712@gmail.com', 'Pendiente', '2025032410283006248573098', 26, 29, NULL, 0, 2, 1, 1, '2025-03-24 16:54:55'),
(142, 'Maria celeste Mena Sanabria ', '402370245', '50672910923', 'celestems131@gmail.com', 'Pendiente', '2025032480383010395258065', 44, 49, NULL, 0, 2, 1, 1, '2025-03-24 17:12:09'),
(144, 'Adriana Mora Fallas ', '108370010', '50688311301', 'amorafa25@gmail.com', 'Pendiente', '91368032', 27, 30, NULL, 0, 2, 1, 1, '2025-03-25 10:05:20'),
(147, 'Stephanie Jiménez Lobo ', '402370177', '50670566405', 'stephanie.m.jim@outlook.es', 'Pendiente', '91691152', 22, 23, NULL, 0, 2, 1, 1, '2025-03-25 13:30:48'),
(148, 'Silvia Vargas Hernández ', '401860689 ', '50685473391', 'mivanpri24@gmail.com', 'Pendiente', '57161273 ', 37, 42, NULL, 0, 2, 1, 1, '2025-03-25 15:45:43'),
(149, 'Adriana Solano', '114160446', '50683082659', 'adri31sc@gmail.com', 'Pendiente', '92261965', 38, 43, NULL, 0, 5, 1, 1, '2025-03-25 19:31:02'),
(150, 'Pamela Álvarez ', '402390755', '50684206680', 'pamelaalvrz04@gmail.com', 'Pendiente', '2025032610283006256190875', 16, 15, NULL, 0, 2, 1, 1, '2025-03-26 09:24:48'),
(151, 'Dylan Arce Vargas ', '402240373', '5067137653', 'dylavargas94@gmail.com', 'Pendiente', '202503261028300628432934', 27, 30, NULL, 0, 2, 1, 1, '2025-03-26 15:48:06'),
(152, 'Fabiola Ninoska Flores Taleno ', '801150817', '50660632350', 'fabiolaflores18@gmail.com', 'Pendiente', '63916383', 49, 54, NULL, 0, 5, 1, 1, '2025-03-26 16:11:34'),
(153, 'María Eugenia Gómez Ulloa ', '700520983', '50664810588', 'marigu5477@gmail.com', 'Pendiente', '93443179', 27, 31, NULL, 0, 2, 1, 1, '2025-03-26 17:27:28'),
(154, 'Betsabeth corea miranda', '206520889', '50684183435', 'betsabeth2012@gmail.com', 'Pendiente', '2025032680383010395960772', 44, 49, NULL, 0, 2, 1, 1, '2025-03-26 17:42:55'),
(155, 'Ingrid gabriela Mena Matarrita', '701730020', '50684780456', 'gabymena045@gmail.com', 'Pendiente', '2025032710283006261196346', 32, 37, NULL, 0, 5, 1, 1, '2025-03-27 08:36:04'),
(156, 'Ana Victoria López Sánchez ', '112130362', '50685837681', 'lopesanchezvictoriana@gmail.com', 'Pendiente', '94159969 BN', 27, 30, NULL, 0, 2, 1, 1, '2025-03-27 10:14:32'),
(157, 'Ligia María Varela Muñoz ', '107370254 ', '50688057888', 'vivivarela68@gmail.com', 'Pendiente', 'BECADA ', 37, 42, NULL, 0, 2, 1, 1, '2025-03-27 10:54:29'),
(158, 'Guisselle Cambronero León ', '401730092 ', '50686051200', 'gleon18@gmail.com', 'Pendiente', '51046001', 22, 23, NULL, 0, 1, 1, 1, '2025-03-27 13:05:20'),
(159, 'Amanda Picado Espinoza ', '402730901', '50672380699', 'emi.picado06@gmail.com', 'Pendiente', '56523621 ', 32, 37, NULL, 0, 5, 1, 1, '2025-03-27 13:25:49'),
(160, 'Thaylin Zúñiga León', '604640539', '50684878814', 'zthay10@gmail.com', 'Pendiente', '55608362', 43, 48, NULL, 0, 2, 1, 1, '2025-03-27 15:47:56'),
(163, 'Kelly Jexabell Sequeira Areas', '155802404327', '50661295332', 'kelly.s.areas94@gmail.com', 'Pendiente', '20250302480383010395140783', 40, 45, NULL, 0, 2, 1, 1, '2025-03-28 12:44:17'),
(164, 'Josseline Daniela Jiménez Rodríguez', '402480522', '50661039812', 'josseline649@gmail.com', 'Pendiente', '57347418 ', 42, 47, NULL, 0, 2, 1, 1, '2025-03-28 14:59:36'),
(165, 'Adriana Durán Villalobos ', '402200967', '50670157613', 'duranvillalobosadri@gmail.com', 'Pendiente', '2025032810283006270431086', 44, 49, NULL, 0, 2, 1, 1, '2025-03-28 15:46:37'),
(167, 'Marianella Eduarte Rodríguez', '402040464', '50671526228', 'nelaer221189@gmail.com', 'Pendiente', '2025032816183220530180186', 27, 30, NULL, 0, 2, 1, 1, '2025-03-28 18:08:25'),
(168, 'Grettel Barrios Barrientos ', '114850081', '50662428017', 'grettelbarriosaj@gmail.com', 'Pendiente', '2025032810283006272233752', 23, 25, NULL, 0, 5, 1, 1, '2025-03-28 18:38:42'),
(169, 'MELANY AGUILAR ARGUELLO', '113620190', '50685643372', 'melanytatiana88@gmail.com', 'Pendiente', '53059090', 27, 30, NULL, 0, 2, 1, 1, '2025-03-28 19:50:47'),
(170, 'Fiorella Chacón Alpizar ', '402390808', '50663741538', 'fiochacon10@hotmail.com', 'Pendiente', '52130084', 44, 49, NULL, 0, 2, 1, 1, '2025-03-29 09:07:10'),
(172, 'María Gabriela Frias Chaves', '107440899', '50688804471', 'gabyfriaschaves@hotmail.com', 'Pendiente', '202503301528300659202510', 19, 21, NULL, 0, 5, 1, 1, '2025-03-31 07:40:39'),
(174, 'Jenny Beatriz Zeledón Zúñiga', '401770098', '50689161701', 'zeledonj09@yahoo.com', 'Pendiente', '98436505', 26, 29, NULL, 0, 2, 1, 1, '2025-03-31 15:07:16'),
(175, 'Patricia Chavarría Villegas', '401280772', '50663953227', 'patriciach142@gmail.com', 'Pendiente', '2025033010283006285158267', 26, 29, NULL, 0, 2, 1, 1, '2025-03-31 15:16:10'),
(177, 'Leda Rodríguez Ruíz ', '302600543', '50670151084', 'leroru04@gmail.com', 'Pendiente', '2025033110283006289202773', 27, 31, NULL, 0, 2, 1, 1, '2025-03-31 15:41:45'),
(179, 'Guadalupe concepción Hernández sandino ', '402300929', '50672975223', 'lupitasandino41117@gmail.com', 'Pendiente', '50521057', 49, 54, NULL, 0, 5, 1, 1, '2025-03-31 11:54:40'),
(181, 'Geovanna Vanessa Córdoba Prendas ', '111900813', '50686461346', 'g.vane081318@gmail.com', 'Pendiente', '91307527', 49, 54, NULL, 0, 5, 1, 1, '2025-03-31 13:14:15'),
(182, 'Elsa Araya Chavarría ', '602320635', '50688664541', 'elsaa2@gmail.com', 'Pendiente', '1471237', 19, 21, NULL, 0, 4, 1, 1, '2025-03-31 14:17:48'),
(183, 'Wendy Campos Rodríguez', '402140567', '50670568174', 'wen.camp141@gmail.com', 'Pendiente', '2025033116183220535707066', 27, 31, NULL, 0, 2, 1, 1, '2025-03-31 20:56:17'),
(184, 'Daniela Arce Murillo', '402040945', '50689911697', 'Danielaam2@hotmail.com', 'Pendiente', '2025040710283006338147477', 26, 29, NULL, 0, 2, 1, 1, '2025-03-31 21:02:26'),
(186, 'Danna Paola Castillo Villalobos ', '119080280', '50687490111', 'dannacastillov2004@gmail.com', 'Pendiente', '2025033110283006289730621', 21, 22, NULL, 0, 2, 1, 1, '2025-03-31 15:16:42'),
(187, 'Heisel Martinez Salgado', '109490626', '50687437876', 'heisel120976@gmail.com', 'Pendiente', '91653776', 21, 22, NULL, 0, 2, 1, 1, '2025-03-31 16:07:01'),
(189, 'Nayeli Susana Soto calvo ', '402610041', '50664054636', 'nayelissoto049@gmail.com', 'Pendiente', '2025033110283006291832613', 32, 37, NULL, 0, 5, 1, 1, '2025-03-31 16:36:20'),
(190, 'Guisselle Cambronero León ', '401730092 ', '50686051200', 'gleon18@gmail.com', 'Pendiente', '53119002', 54, 60, NULL, 0, 2, 1, 1, '2025-03-31 18:00:31'),
(191, 'Lorena Cubillo Lobo ', '106210599', '50688950020', 'lorenacubillo93@gmail', 'Pendiente', '93499377', 42, 47, NULL, 0, 2, 1, 1, '2025-04-01 14:55:40'),
(192, 'Yorleny Fernández ', '107500884', '50685898621', 'darialexa99@gmail.com', 'Pendiente', '2025040280383010398683444', 60, 65, NULL, 0, 2, 1, 1, '2025-04-02 10:33:28'),
(193, 'Yaireth Arias Aguilar ', '401840532', '50687385271', 'yary0584@gmail.com', 'Pendiente', '55644971', 60, 65, NULL, 0, 2, 1, 1, '2025-04-02 10:44:25'),
(194, 'Milena Espinoza Rojas ', '4-0180-0485 ', '50660565826', 'milenaer12@gmail.com', 'Pendiente', 'BECADA', 60, 65, NULL, 0, 2, 1, 1, '2025-04-02 11:11:21'),
(195, 'María Elena Ramírez Ramírez', '402350139', '50689644084', 'mr84704@gmial.com', 'Pendiente', '95065689', 27, 31, NULL, 0, 2, 1, 1, '2025-04-02 20:02:58'),
(197, 'Ana Jane Camacho Soto', '401070669', '50684416868', 'radiobarvacr@gmail.com', 'Pendiente', 'BECADA', 31, 36, NULL, 0, 2, 1, 1, '2025-04-02 20:32:40'),
(198, 'Glenda Miranda Román', '402250682', '50685634514', 'glenda.mr04@gmail.com', 'Pendiente', '2025040210283006304709081', 61, 67, NULL, 0, 2, 1, 1, '2025-04-02 15:25:09'),
(199, 'Marvin Andrei González Vargas ', '116280215', '50687160815', 'marvin95112009@hotmail.com', 'Pendiente', '54662616', 54, 60, NULL, 0, 2, 1, 1, '2025-04-02 16:52:02'),
(200, 'Lourdes mora soto', '205470593', '50670521224', 'lourdesmorasoto@gmail.com', 'Pendiente', '58800066', 19, 21, NULL, 0, 4, 1, 1, '2025-04-03 08:58:28'),
(201, 'Tatiana Villafuerte Retana ', '402490573 ', '50660060595', 'tvillafuerte.04@outlook.com', 'Pendiente', '2025040310283006309601601', 19, 21, NULL, 0, 5, 1, 1, '2025-04-03 10:11:32'),
(202, 'Xinia Alfaro Bonilla', '401480881', '50688788428', 'xaxalfaroo@gmail.com', 'Pendiente', '2025040382183010357291432', 28, 32, NULL, 0, 2, 1, 1, '2025-04-03 16:18:06'),
(203, 'María Patricia Conejo Rojas', '204220150', '50689894536', 'patriciaconejo@hotmail.com', 'Pendiente', '2025032582183010353624037', 28, 32, NULL, 0, 2, 1, 1, '2025-04-03 17:53:44'),
(204, 'Melissa García Rodríguez ', 'E023105', '50663038834', 'mr8012793@gmail.com', 'Pendiente', '2025040310283006310739693', 54, 60, NULL, 0, 2, 1, 1, '2025-04-03 13:28:34'),
(206, 'Sussana Bolaños Villalobos ', '401940399', '50664887766', 'mariakpuravida2018@gmail.com', 'Pendiente', '29375362', 54, 60, NULL, 0, 2, 1, 1, '2025-04-04 08:39:23'),
(207, 'Karina Esquivel Solano ', '110970348', '50685491849', 'kriness@gmail.com', 'Pendiente', '50216261', 15, 14, 'SINPE Móvil', 0, 0, 1, 1, '2025-04-04 10:28:05'),
(208, 'Ileana Cordero León', '401620477', '50685468134', 'ilecorleo@yahoo.com', 'Pendiente', '95564391', 40, 45, NULL, 0, 2, 1, 1, '2025-04-04 17:25:19'),
(209, 'Martha Elena Meléndez Monge', '106700550', '50688206921', 'marthammonge@hotmail.com', 'Pendiente', '6286422231', 40, 45, NULL, 0, 1, 1, 1, '2025-04-04 17:29:32'),
(210, 'Ariela Garita Flores', '120720203', '50685384177', 'floreslucy08@gmail.com', 'Pendiente', '28632758', 27, 31, NULL, 0, 2, 1, 1, '2025-04-04 17:44:13'),
(211, 'Lucía Flores Fonseca', '111260671', '50688323567', 'floreslucy08@gmail.com', 'Pendiente', '28632758', 27, 31, NULL, 0, 2, 1, 1, '2025-04-04 17:45:03'),
(213, 'Deyanira Castillo Chaves', '401390551', '50684657497', 'deyacastillo2@gmail.com', 'Pendiente', 'BECADA', 62, 68, NULL, 0, 2, 1, 1, '2025-04-04 18:06:42'),
(214, 'Maribel Berrocal Miranda', '401400554', '50685969834', 'maribelberro@gmail.com', 'Pendiente', '2025040416183220542898083', 62, 68, NULL, 0, 2, 1, 1, '2025-04-04 18:10:29'),
(216, 'Cecilia Dolores Arauz Robleto', '800460437', '50664790267', 'ceciarauz50@gmail.com', 'Pendiente', 'PRUEBNWESQWEFQef', 15, 14, NULL, 0, 0, 1, 1, '2025-04-04 20:03:36'),
(217, 'Marifer Estrada Altamirano ', '504370383', '50664852116', 'estrada.altamirano20marifer@gmail.com', 'Pendiente', '55513638', 54, 60, NULL, 0, 2, 1, 1, '2025-04-05 17:21:28'),
(218, 'Shirley Patricia Marín Muñoz ', ' 106780125', '50683713717', 'shmarin13@hotmail.com', 'Pendiente', '90604492', 19, 21, NULL, 0, 5, 1, 1, '2025-04-05 20:00:07'),
(220, 'Susan Melissa Moya Sánchez', '112440248', '50689122239', 'moyasanchezmelissa@gmail.com', 'Pendiente', '2025040580383010400157796', 25, 28, NULL, 0, 2, 1, 1, '2025-04-07 17:51:59'),
(221, 'Flor María Cascante Fernández', '104130614', '50688820390', 'fmcasf@gmail.com', 'Pendiente', '2025040610283006328573436', 19, 21, 'SINPE Móvil', 0, 5, 1, 1, '2025-04-07 18:00:20'),
(222, 'Melany Montero Rivera', '402540870', '50661679051', 'melanymonterorivera@gmail.com', 'Pendiente', '2025040710283006334601324', 54, 60, NULL, 0, 2, 1, 1, '2025-04-07 18:08:16'),
(223, 'Magaly Solorzano Guerrero', '701590004', '50687518714', 'maga.gata35@gmail.com', 'Pendiente', '17294056', 21, 22, NULL, 0, 2, 1, 1, '2025-04-07 18:13:57'),
(224, 'Andrea Vega Morales', '603820205', '50689073506', 'keizu08@gmail.com', 'Pendiente', '15399127', 21, 22, NULL, 0, 2, 1, 1, '2025-04-07 18:17:40'),
(225, 'Kristal Brillit León Orellana ', '402620221 ', '50686420135', 'oreleonkriss80@gmail.com', 'Pendiente', '92637568', 64, 70, NULL, 0, 2, 1, 1, '2025-04-07 13:02:01'),
(226, 'Silvia Orellana Díaz', '122200475400', '50662386651', 'orellanasilvia5050@gmail.com', 'Pendiente', '525236364', 49, 54, NULL, 0, 5, 1, 1, '2025-04-07 19:27:30'),
(227, 'Bella Lorena Rivas Sosa', '122200041931', '50687645626', 'blrivassosa@gmail.com', 'Pendiente', '52311605', 49, 54, NULL, 0, 5, 1, 1, '2025-04-07 19:33:53'),
(228, 'Jacqueline Gutiérrez Duarte', '401740279', '50670196887', 'jackeline.g.d.81@gmail.com', 'Pendiente', '54639818', 49, 54, NULL, 0, 5, 1, 1, '2025-04-08 14:13:05'),
(229, 'Maribel Sánchez Azofeifa ', '111230176 ', '50683996796', 'maribellsna@gmail.com', 'Pendiente', '58981262', 60, 65, NULL, 0, 2, 1, 1, '2025-04-08 10:21:53'),
(230, 'Giuliana Sophía Vargas Mendoza', '119880006', '50660071602', 'vargasgiuliana1602@gmail.com', 'Pendiente', '937889590', 65, 71, NULL, 0, 2, 1, 1, '2025-04-08 10:31:47'),
(231, 'María Yael Solano Méndez', '108860142', '50683133584', 'yaelita2806@gmail.com', 'Pendiente', '2025040715283006655368623', 25, 28, NULL, 0, 2, 1, 1, '2025-04-08 16:55:14'),
(234, 'Kimberly Lhamas Mohs', '112180858', '50663089531', 'kimlhamasmohs@gmail.com', 'Pendiente', '59000036', 19, 21, NULL, 0, 5, 1, 1, '2025-04-09 15:16:03'),
(235, 'Tracy Montero Mora', '115430513', '50683891276', 'nanim264@gmail.com', 'Pendiente', '62585129', 62, 68, NULL, 0, 2, 1, 1, '2025-04-09 16:06:50'),
(237, 'Priscilla Vargas González', '401960112', '50683867509', 'prixi410@gmail.com', 'Pendiente', '2025040910283006344302972', 64, 70, NULL, 0, 2, 1, 1, '2025-04-09 16:19:00'),
(238, 'Mariela Chaves Arias', '401970264', '50685044046', 'chaves.mari.sr@gmail.com', 'Pendiente', '95176933', 27, 31, NULL, 0, 2, 1, 1, '2025-04-09 16:34:41'),
(239, 'Silvia Ramírez Zúñiga', '108430014', '50672010885', 'sramirezz@yahoo.es', 'Pendiente', '94847930', 60, 65, NULL, 0, 2, 1, 1, '2025-04-10 14:46:08'),
(240, 'Valery Rebeca Vargas Segura', '402580327', '50685455802', 'valesegura341@gmail.com', 'Pendiente', '2025041010283006350229918', 60, 65, NULL, 0, 2, 1, 1, '2025-04-10 16:52:03'),
(241, 'Jeannette Chavarría Campos', '106320197', '50661193507', 'jecacha17@hotmail.com', 'Pendiente', '2025041015283006670637486', 18, 20, NULL, 0, 2, 1, 1, '2025-04-10 17:22:45'),
(242, 'Habraham Miranda Morales', '402810689', '50661711537', 'estrellamoralesbrenes344@gmail.com', 'Pendiente', '91458526', 43, 48, NULL, 0, 2, 1, 1, '2025-04-14 14:30:04'),
(243, 'Catalina Vargas Hernández', '115770102', '50687233561', 'cata07vh@gmail.com', 'Pendiente', '2025041010283006351844413', 23, 25, NULL, 0, 5, 1, 1, '2025-04-14 15:24:08'),
(244, 'Catalina Vargas Hernández', '115770102', '50687233561', 'cata07vh@gmail.com', 'Pendiente', '2025041010283006351824178', 38, 43, NULL, 0, 5, 1, 1, '2025-04-14 15:26:35'),
(245, 'Eveling Juniette Suazo Romero', '155826823226', '50685997639', 'juniethsuazo@gmail.com', 'Pendiente', '99615201', 64, 70, NULL, 0, 2, 1, 1, '2025-04-14 15:46:59'),
(246, 'Flordeliz Vega Alavarado', '401780380', '50663126760', 'fvega2354@gmail.com', 'Pendiente', '04074115', 61, 66, NULL, 0, 1, 1, 1, '2025-04-14 09:56:56'),
(247, 'Zaray Chavez Ocampo', '402340709', '50672609955', 'zaraychavesocampo@gmail.com', 'Pendiente', '2025032510283006250390701 el 25/03/2025 banco BAC', 61, 66, NULL, 0, 2, 1, 1, '2025-04-14 09:59:46'),
(248, 'Erika Isabel López Mejía', '155813950517', '50688617062', 'lopezmejiaerika8@gmail.com', 'Pendiente', '11172869', 42, 47, NULL, 0, 2, 1, 1, '2025-04-14 16:06:42'),
(249, 'Martha León López', '104740370', '50670815196', 'marthalelop@gmail.com', 'Pendiente', '50090365', 43, 48, NULL, 0, 2, 1, 1, '2025-04-14 16:25:17'),
(250, 'Leticia Villalobos Ramírez', '108760100', '50683379728', 'lvillalobos032@hotmail.com', 'Pendiente', '16294702', 44, 49, NULL, 0, 2, 1, 1, '2025-04-14 16:28:17'),
(251, 'Elieth Sánchez Chaves', '900640223', '50688958810', 'macha2631@gmail.com', 'Pendiente', '2025041410283006371749536', 31, 36, NULL, 0, 2, 1, 1, '2025-04-14 16:57:52'),
(252, 'Yajaira Garro González', '401690916', '50688268104', 'yayigarro@yahoo.com', 'Pagado', '90639531 ', 66, 72, NULL, 0, 0, 1, 1, '2025-04-14 11:09:48'),
(253, 'Verónica Dubón Vanegas', '134000227829', '50688831870', 'facturaciondigital2020gmail.com', 'Pendiente', '92272009', 31, 36, NULL, 0, 2, 1, 1, '2025-04-14 17:26:33'),
(254, 'Karla Marcela Campos Cortés', '401690527', '50664561271', 'kc411292@gmail.com', 'Pendiente', '96725179', 64, 70, NULL, 0, 2, 1, 1, '2025-04-14 18:35:38'),
(255, 'Kassandra Arias Lindor', '402290565', '50685505319', 'ariaslindork@gmail.com', 'Pendiente', '97520060', 35, 40, NULL, 0, 2, 1, 1, '2025-04-14 18:51:34'),
(256, 'María Patricia Conejo Rojas', '204220150', '50689894536', 'patriciaconejo@hotmail.com', 'Pendiente', '2025032582183010353624037', 18, 19, NULL, 0, 2, 1, 1, '2025-04-14 21:10:10'),
(257, 'María José Sanabria Garro', '113380724', '50683380999', 'mjsanabria03@gmail.com', 'Pendiente', '202504141028300637769048', 35, 40, NULL, 0, 2, 1, 1, '2025-04-14 22:20:42'),
(258, 'Nicole Brenes Solís', '118080544', '50684130962', 'nicolbrso1204@gmail.com', 'Pendiente', '56418146', 65, 71, NULL, 0, 2, 1, 1, '2025-04-15 14:52:34'),
(259, 'Paola Solís Meza', '114730485', '50662970706', 'jenepao460@gmail.com', 'Pendiente', '93990061', 64, 70, NULL, 0, 2, 1, 1, '2025-04-15 21:03:30'),
(260, 'Susana Segura Cortés', '401990430', '50688365492', 'susansc45@gmail.com', 'Pendiente', '94356295', 63, 69, NULL, 0, 2, 1, 1, '2025-04-15 21:38:20'),
(261, 'Nicole Melissa Solís Salgado', '117850083', '50664723689', 'melissasolis0770@gmail.com', 'Pendiente', '52987285', 65, 71, NULL, 0, 2, 1, 1, '2025-04-16 17:52:06'),
(262, 'Daniela María Oconitrillo Garita', '402020212', '50688194962', 'daniocog@gmail.com', 'Pendiente', '50003691', 65, 71, NULL, 0, 2, 1, 1, '2025-04-16 17:55:41'),
(263, 'María Delgado Calderón', '108320445', '50672605455', 'maria.delg.7389@gmail.com', 'Pendiente', '20250416102183006386374575', 18, 20, NULL, 0, 2, 1, 1, '2025-04-16 18:07:29'),
(264, 'Verónica Patricia Gudiel Solís', '116730814', '50671927475', 'vgudiel662@gmail.com', 'Pendiente', '91010098', 32, 37, NULL, 0, 5, 1, 1, '2025-04-22 15:07:39'),
(265, 'María Gabriela Frias Chaves', '107440899', '50688804471', 'gabyfriaschaves@hotmail.com', 'Pendiente', '2025041615283006712558190', 22, 23, NULL, 0, 2, 1, 1, '2025-04-22 15:20:11'),
(266, 'Ana Victoria Vásquez Anchía', '401880650', '50661665281', 'avictoria85@gmail.com', 'Pendiente', '2025041810283006397849853', 63, 69, NULL, 0, 2, 1, 1, '2025-04-22 15:58:39'),
(267, 'Evelyn Daniela Alfaro Fonseca', '402330790', '50689689013', 'eve_alfaro@hotmail.com', 'Pendiente', '2025041910283006400942263', 63, 69, NULL, 0, 2, 1, 1, '2025-04-22 16:40:51'),
(268, 'Diana Vanessa Jirón Dávila', '155840672617', '50672957820', 'dianavanessadavila@gmail.com', 'Pendiente', '2025042110283006409763995', 64, 70, NULL, 0, 2, 1, 1, '2025-04-22 16:47:50'),
(269, 'Micaela Camacho Vargas', '401061096', '50689110888', 'micaelacv13@gmail.com', 'Pendiente', '2025042215183010535376495', 22, 23, NULL, 0, 2, 1, 1, '2025-04-22 18:07:21'),
(271, 'Saily Sandoval Ramírez', '402330457', '50683872688', 'sailysandovalr@gmail.com', 'Pendiente', 'BECADA', 68, 74, NULL, 0, 1, 1, 1, '2025-04-22 22:22:10'),
(272, 'Ana Ligia Monge Quesada', '301971133', '50688356135', 'analigiamongeq@gmail.com', 'Pendiente', '2025041081483000620934621 el 10/04/2025', 68, 74, NULL, 0, 1, 1, 1, '2025-04-22 22:24:43'),
(273, 'Adrián Pérez Mendoza', '402820392', '50687347775', 'mendozamarbellys44@gmail.com', 'Pendiente', '92954518', 49, 54, NULL, 0, 5, 1, 1, '2025-04-22 22:35:29'),
(274, 'Tamara Moreno Ureña', '114600452', '50672901911', 'tamaramoreno26@hotmail.com', 'Pagado', '20250407102830063366901772', 66, 72, NULL, 0, 0, 1, 1, '2025-04-23 18:49:34'),
(275, 'Maricel Acuña Marín', '401860213', '50688709645', 'mari1126@hotmail.es', 'Pagado', '2025042310283006420937167', 66, 72, NULL, 0, 0, 1, 1, '2025-04-23 18:58:12'),
(276, 'Catalina Campos Cortés', '402190103', '50661127211', 'catalinacampos066@gmai.com', 'Pendiente', '94439633', 64, 70, NULL, 0, 2, 1, 1, '2025-04-23 21:57:08'),
(277, 'Ana Isabel Reyes Herra', '106360220', '50683825341', 'anareyesherra@outlook.com', 'Pendiente', '76453311 Y 74834191', 64, 70, NULL, 0, 2, 1, 1, '2025-04-23 22:13:59'),
(279, 'Karol Gómez Cortés', '304260599', '50671675305', 'karo881414@gmail.com', 'Pendiente', '2025042310283006422305164', 61, 66, NULL, 0, 2, 1, 1, '2025-04-23 22:32:00'),
(280, 'María Fernanda Pérez Chavarría', '402130665', '50688010207', 'fernanda23.23@hotmail.com', 'Pendiente', '2025040110283006300900811', 61, 66, NULL, 0, 2, 1, 1, '2025-04-23 22:44:33'),
(281, 'Yareliz Alvardao Cambronero', '114320172', '50686504693', 'yarelizac@hotmail.com', 'Pagado', '52626964', 66, 72, NULL, 0, 0, 1, 1, '2025-04-23 23:01:12'),
(282, 'Ana Isabel Cruz Cruz', '700550620', '50687123608', 'casmanuel1@yahoo.com', 'Pendiente', 'FT25113M4B', 18, 19, NULL, 0, 2, 1, 1, '2025-04-23 23:16:17'),
(283, 'Dayana Alfaro Esquivel', '401970615', '50672032960', 'daalfaroe@gmail.com', 'Pendiente', '95361436', 65, 71, NULL, 0, 2, 1, 1, '2025-04-24 16:40:57'),
(284, 'Josebeth Arrieta Zúñiga', '402750635', '50686084624', 'jojoarixx@gmail.com', 'Pendiente', '95663994', 65, 71, NULL, 0, 2, 1, 1, '2025-04-24 20:13:13'),
(285, 'Cindy Gutiérrez Abarca', '402360387', '50689525072', 'gutierreza.facturas@gmail.com', 'Pendiente', '2025042510283006430123177', 38, 43, NULL, 0, 5, 1, 1, '2025-04-25 14:13:20'),
(286, 'Verónica Guevara Corrales ', '111030051', '50688272555', 'veronik29@yahoo.com', 'Pendiente', '2025042416183220572360334', 63, 69, NULL, 0, 2, 1, 1, '2025-04-25 14:36:56'),
(287, 'Rose Miranda González', '110410474', '50687058435', 'odontomundo@yahoo.com', 'Pendiente', '2025042410283006428599041', 65, 71, NULL, 0, 2, 1, 1, '2025-04-25 14:50:27'),
(288, 'Gabriela Arce Rubí', '108080542', '50689229987', 'garce0211@gmail.com', 'Pendiente', '96274494', 22, 23, NULL, 0, 2, 1, 1, '2025-04-25 14:55:31'),
(289, 'Yamileth Ruíz Vargas', '104630531', '50688606307', 'yami@transportes-chaves.com', 'Pendiente', '2025042415283006760598725', 31, 36, NULL, 0, 2, 1, 1, '2025-04-25 16:10:43'),
(290, 'María Fernanda Alvarado Jiménez', '116000228', '50684503385', 'andreysolis8916@gmail.com', 'Pendiente', '96817312 ', 65, 71, NULL, 0, 2, 1, 1, '2025-04-25 17:00:26'),
(291, 'María de los Ángeles Miranda Palma', '401080393', '50688104611', 'mirandapalmamarielos@gmail.com', 'Pendiente', '99529242', 62, 68, NULL, 0, 2, 1, 1, '2025-04-25 18:17:00'),
(292, 'Mariana Sánchez Paniagua', '402300619', '50660049256', 'marisanchez-1996@hotmail.com', 'Pendiente', '63828454', 64, 70, NULL, 0, 2, 1, 1, '2025-04-25 20:36:40'),
(294, 'Abril Gabriela Vindas Castro', '402550825', '50672868191', 'avindas2014gmail.com', 'Pendiente', '92358421', 70, 76, NULL, 0, 3, 1, 1, '2025-04-25 22:17:57'),
(295, 'Yendry Díaz Valverde', '701670581', '50663562510', 'yendrydiazv@gmail.com', 'Pendiente', '52353242', 70, 76, NULL, 0, 3, 1, 1, '2025-04-25 22:19:46'),
(296, 'María Luisa Acosta Zárate', '119950153', '50660142698', 'malua2007@gmail.com', 'Pendiente', '2025042510283006433666079', 61, 66, NULL, 0, 2, 1, 1, '2025-04-25 22:31:03'),
(297, 'Gisela Espinoza Avelares', '155819996611', '50661675144', 'giseespinoza94@hotmail.com', 'Pendiente', '97443556', 61, 66, NULL, 0, 2, 1, 1, '2025-04-25 22:37:25'),
(298, 'Lourdes María Arce Espinoza', '401560689', '50683043666', 'arcelourdes1@gmail.com', 'Pendiente', '97514544', 61, 66, NULL, 0, 2, 1, 1, '2025-04-25 23:14:17'),
(299, 'Graciela Carolina Medrano Aburto', 'C03828961', '50672669943', 'medranograciela156@gmail.com', 'Pendiente', '2025042810283006447736860', 61, 66, NULL, 0, 2, 1, 1, '2025-04-28 20:33:12'),
(300, 'María de los Ángeles Hernández Hernández', '401320083', '50685461917', 'marieloshernandez086@gmail.com', 'Pendiente', 'BECADA', 71, 77, NULL, 0, 5, 1, 1, '2025-04-28 22:35:11'),
(301, 'Ana Jiménez Arroyo', '109590444', '50688897595', 'infogrupoakara@gmail.com', 'Pendiente', '2025042810283006453321436', 71, 77, NULL, 0, 5, 1, 1, '2025-04-29 14:55:07'),
(302, 'Jacqueline Gutiérrez Duarte', '401740279', '50670196887', 'jackeline.g.d.81qgmail.com', 'Pendiente', '88950544', 70, 76, NULL, 0, 3, 1, 1, '2025-04-29 15:11:58'),
(303, 'Samantha Araya Jiménez', '402800481', '50663771187', 'saudyjisa87@otlook.es', 'Pendiente', '88369722', 61, 66, NULL, 0, 2, 1, 1, '2025-04-29 16:28:05'),
(304, 'Joselin Chen Chaves ', '604470170', '50687239696', 'joselynchen24@gmail.com', 'Pendiente', '98837537', 38, 43, NULL, 0, 5, 1, 1, '2025-05-02 21:10:12');

--
-- Disparadores `matriculas`
--
DELIMITER $$
CREATE TRIGGER `after_delete_matricula` BEFORE DELETE ON `matriculas` FOR EACH ROW BEGIN
    INSERT INTO desercion (Nombre, Cedula, Telefono, Correo, estadoPago, comprobante, formaPago)
    VALUES (OLD.Nombre, OLD.Cedula, OLD.Telefono, OLD.Correo, OLD.estadoPago, OLD.comprobante, OLD.formaPago);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `insert_clientes_if_not_exists` AFTER INSERT ON `matriculas` FOR EACH ROW BEGIN
    -- Verifica si la cédula ya existe en la tabla Personas
    IF NOT EXISTS (SELECT 1 FROM bitacoria_clientes WHERE CEDULA = NEW.Cedula) THEN
        -- Si la cédula no existe, inserta los datos en la tabla Personas
        INSERT INTO bitacoria_clientes (NOMBRE, CEDULA, TELEFONO, CORREO)
        VALUES (NEW.Nombre, NEW.Cedula, NEW.Telefono, NEW.Correo);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientosdinero`
--

CREATE TABLE `movimientosdinero` (
  `id` int(11) NOT NULL,
  `tipoMovimiento` int(11) NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `idCurso` int(11) NOT NULL,
  `idMatricula` int(11) NOT NULL,
  `NombreCurso` varchar(255) NOT NULL,
  `Envia` varchar(255) NOT NULL,
  `Recibe` varchar(255) NOT NULL,
  `CedulaClientePaga` varchar(45) DEFAULT NULL,
  `NombreClientePaga` varchar(45) DEFAULT NULL,
  `TelefonoclientePaga` varchar(45) DEFAULT NULL,
  `EmailClientePaga` varchar(45) DEFAULT NULL,
  `Notas` varchar(255) DEFAULT NULL,
  `comprobante` varchar(100) DEFAULT NULL,
  `fecha` datetime NOT NULL,
  `sePagoPorcentaje` tinyint(1) NOT NULL,
  `idPagoProfesor` int(11) NOT NULL,
  `idProfesor` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `movimientosdinero`
--

INSERT INTO `movimientosdinero` (`id`, `tipoMovimiento`, `monto`, `idCurso`, `idMatricula`, `NombreCurso`, `Envia`, `Recibe`, `CedulaClientePaga`, `NombreClientePaga`, `TelefonoclientePaga`, `EmailClientePaga`, `Notas`, `comprobante`, `fecha`, `sePagoPorcentaje`, `idPagoProfesor`, `idProfesor`) VALUES
(70, 1, 15000.00, 44, 28, 'Repostería', 'CLIENTE', 'SISTEMA', '701100837', 'Milena Mendoza Valenciano', '50689932919', 'mmendoza@una.ac.cr', '', '94210067', '2025-03-07 18:09:13', 1, 0, NULL),
(71, 1, 15000.00, 40, 37, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '402730546', 'Valentina gabriela Morales Sánchez ', '50684490254', 'valentinagabriela1406@gmail.com', '', '30860478', '2025-03-07 18:49:19', 1, 0, NULL),
(72, 1, 15000.00, 43, 56, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '111560465', 'Marian Carillo Valverde ', '50670155093', 'valerysala07@gmail.com', '', '32933781', '2025-03-07 22:40:07', 1, 0, NULL),
(73, 1, 15000.00, 37, 92, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '401950754 ', 'Lidia Ramírez Bogantes ', '50688792586', 'lidiramiboga25@hotmail.com', 'Numero de Documento: 52100985 - 17/3/25', '2025031580383010392100985', '2025-03-20 04:47:50', 1, 0, NULL),
(74, 1, 15000.00, 32, 94, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '155818926626', 'Concepción de los angeles González galan ', '50672982489', 'concegonzalez85@gmail.com', '# Documento 98667352 - 17/03/25', '98667352', '2025-03-20 04:57:07', 1, 0, NULL),
(75, 1, 15000.00, 45, 88, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '105740788', 'Norma Moreira Chaves', '50688304982', 'nmoreirach@gmail.com', '# Documento: 59135871 -  03/03/25', 'Ft25073BVY6N', '2025-03-20 05:10:19', 1, 0, NULL),
(76, 1, 15000.00, 45, 91, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '401870945', 'Laura Moreno González ', '50663604228', 'laumoreno237@gmail.com', '# documento 50127044\npago el día 14/3/2024', '50127044', '2025-03-22 04:45:24', 1, 0, NULL),
(77, 1, 15000.00, 27, 90, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '109900292', 'Karol Chinchilla Barrientos', '50687053610', 'karolchiba40@gmail.com', '3 documento 55431786\npago el dia 14/3/2025', '2025031410283006185431786', '2025-03-22 04:48:59', 1, 0, NULL),
(78, 1, 15000.00, 22, 89, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '108950861', 'Flor María Vega Rojas ', '50660062099', 'florvega010@gmail.com', '# documento 55067381\npago el dia 14/3/2025', '2025031410283006185067381', '2025-03-22 04:50:24', 1, 0, NULL),
(79, 1, 15000.00, 45, 88, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '105740788', 'Norma Moreira Chaves', '50688304982', 'nmoreirach@gmail.com', '# documento 57600122\npago el dia 14/3/2025', 'Ft25073BVY6N', '2025-03-22 04:51:46', 1, 0, NULL),
(80, 1, 15000.00, 44, 86, 'Repostería', 'CLIENTE', 'SISTEMA', '702680854', 'Dafnaly Mitre Hernandez', '50664181317', 'dafmh1228@gmail.com', '# documento 52966558\npago el dia 14/3/2025', '2025031410283006182966558', '2025-03-22 04:54:05', 1, 0, NULL),
(81, 1, 15000.00, 43, 87, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '108080245', 'Marycruz Ocampo Aguilar ', '50688388581', 'maricruzocampo@yahoo.es', '# documento 93830653\npago el dia 14/3/2025', '93830653', '2025-03-22 05:01:36', 1, 0, NULL),
(82, 1, 15000.00, 43, 84, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '800770707', 'Mercedes Manzanares Barahona', '50687922465', 'william.Bermudez.ramirez@gmail.com', '# documento 93775791\npago el dia 14/3/2025', '93775791', '2025-03-22 05:05:52', 1, 0, NULL),
(83, 1, 15000.00, 40, 82, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '401850396', 'Carolina Barquero Brenes ', '50683346472', 'cvjbarquero@gmail.com', '# documento 92912697\npago el dia 13/3/2025', '92912697', '2025-03-22 05:12:05', 1, 0, NULL),
(84, 1, 15000.00, 45, 71, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '113620824', 'Greidy Hernández Esteban ', '50670119590', 'greidy.hernandez@hotmail.com', '#documento 56596350\npago el dia   11/3/2025', '56596350', '2025-03-22 05:28:09', 1, 0, NULL),
(85, 1, 15000.00, 17, 21, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '602470850', 'Carla Hernández Solís', '50689325062', 'karlahs1872@gmail.com', '#  documento 56083739\npago el dia 11/3/2025', '2025030710283006142571381', '2025-03-22 05:29:48', 1, 0, NULL),
(86, 1, 15000.00, 45, 69, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '401840724', 'Karen Camacho Valerio', '50688103763', 'kata1308@gmail.com', '#documeto 51812533\npago el dia 11/3/2025', 'FT2507087TS9', '2025-03-22 05:32:43', 1, 0, NULL),
(87, 1, 15000.00, 17, 11, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '108160250', 'Elizabeth Campos Hernández ', '50683436720', 'camposeli@hotmail.es', '# documento 53117597\npago el 6/3/2025', '23117597', '2025-03-23 22:57:39', 1, 0, NULL),
(88, 1, 15000.00, 37, 49, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '110210125', 'Ana Porras Segura', '50685974692', 'anacripo@hotmail.com', '# documento 59979232\npago el 7/3/2025', '24724237', '2025-03-23 23:04:48', 1, 0, NULL),
(89, 1, 15000.00, 17, 14, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '2473966', 'Guadalupe Murillo Espinoza', '50685068415', 'murillog972@gmail.com', '', '20250307814830000600299998', '2025-03-23 23:13:58', 1, 0, NULL),
(90, 1, 15000.00, 43, 20, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '206690166', 'Catalina Sánchez Sánchez ', '50683345869', 'cata23ss@hotmail.com', '# documento 93858099\n7/3/2025', '93858099', '2025-03-23 23:17:31', 1, 0, NULL),
(91, 1, 15000.00, 23, 26, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '107700528', 'Patricia Bermudez Ramírez ', '50688472954', 'patribr14@gmail.com', '# documento 58743050\n7/3/2025', '2025030780383010388743050', '2025-03-23 23:19:08', 1, 0, NULL),
(92, 1, 15000.00, 37, 36, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '6247850', 'Carla Hernández Solis', '50689325062', 'karlahs1872@gmail.com', '# documento 59082076\n7/3/2025', '29082076', '2025-03-23 23:22:37', 1, 0, NULL),
(93, 1, 15000.00, 32, 39, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '117870417', 'Jesenia Torres Vargas', '50686264451', 'jestorres03@hotmail.com', '# documento 93960257\n7/3/2025', '93960257', '2025-03-23 23:24:05', 1, 0, NULL),
(94, 1, 15000.00, 44, 51, 'Repostería', 'CLIENTE', 'SISTEMA', '117640290', 'Krysta Nicole Navarro Carvajal', '50687842662', 'nicolnc02@gmail.com', '# documento 54377155\n7/3/2025', '2025030710283006144377155', '2025-03-23 23:28:46', 1, 0, NULL),
(95, 1, 15000.00, 44, 52, 'Repostería', 'CLIENTE', 'SISTEMA', '402110502', 'Irene Villalobos León', '50689158623', 'ire_villalobos_18@hotmail.com', '# documento 94329402\n7/3/2025', '94329402', '2025-03-23 23:29:42', 1, 0, NULL),
(96, 1, 15000.00, 27, 53, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '1-0621-0927 ', 'Marjorie Bonilla Benavides ', '50683496850', 'yuriboni64@gmail.com', '# documento 57600371\n7/3/2025', '2025030782183010347600371', '2025-03-23 23:30:51', 1, 0, NULL),
(97, 1, 15000.00, 27, 54, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '104520944', 'Elizabeth Vargas López ', '50661148230', 'marieliza317@gmail.com', '# documento 56548037\n7/3/2025', 'FT250666LXFQ', '2025-03-23 23:32:05', 1, 0, NULL),
(98, 1, 15000.00, 17, 12, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '110210125', 'Ana Porras Segura', '50685974692', 'anacripo@hotmail.com', '# documento 59979232\n7/3/2025', '247237772', '2025-03-23 23:35:45', 1, 0, NULL),
(99, 1, 15000.00, 23, 65, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '112860687', 'Kerlyn Fernández Obando ', '50683193219', 'kerlyn_07@yahoo.es', '# documento 52303749\n10/3/2025', '52303749', '2025-03-23 23:42:58', 1, 0, NULL),
(100, 1, 15000.00, 27, 66, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '304410397', 'Angelica Ramirez', '50683032314', 'arami13@gmail.com', '# documento 53872966\n10/3/2025', '20250310102830061638722966', '2025-03-23 23:44:06', 1, 0, NULL),
(101, 1, 15000.00, 27, 67, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', 'Pasaporte N08039338', 'Maria de Guadalupe Estrada Medrano', '50672354223', 'ing.guadalupe.estrada@gmail.com', '# documento 54091911\n10/3/2025', 'BCR REFERENCIA 2025031015283006454091911', '2025-03-23 23:46:37', 1, 0, NULL),
(102, 1, 15000.00, 27, 90, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '109900292', 'Karol Chinchilla Barrientos', '50687053610', 'karolchiba40@gmail.com', '# documento 55431786\n14/3/2025', '2025031410283006185431786', '2025-03-24 00:48:25', 1, 0, NULL),
(103, 1, 15000.00, 15, 121, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '2 462 507', 'Xinia Arguedas Vega ', '50671435344', 'xiniarguedas45@gmail.com', 'BECADA', 'Becada ', '2025-03-24 01:10:27', 1, 0, NULL),
(104, 1, 15000.00, 38, 124, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '113830662', 'Mariela Rojas Calderón ', '50687681082', 'marie2489@gmail.com', '# documento 59478704\n21/3/2025', '958468895', '2025-03-24 02:25:22', 1, 0, NULL),
(105, 1, 15000.00, 44, 123, 'Repostería', 'CLIENTE', 'SISTEMA', '801270603 ', 'Wendy Lorena raudales moncada ', '50685765304', 'wendyraudalesm@gmail.com', '# documento 94835880\n20/3/2025', '94835880', '2025-03-24 02:31:20', 1, 0, NULL),
(106, 1, 15000.00, 22, 99, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '303330605 ', 'Maricel Rodriguez Serrano ', '50686195081', 'maricel111974@gmail.com', 'BECADA', 'BECADA', '2025-03-24 02:34:27', 1, 0, NULL),
(107, 1, 15000.00, 45, 118, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '11005230', 'Hellen Alvarado Mora ', '50660294024', 'hellenalvarado.528@gmail.com', '# documento 57476435\n19/3/2025', '17476435', '2025-03-24 02:37:43', 1, 0, NULL),
(108, 1, 15000.00, 32, 113, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '4 02690283', 'Brittany Sanchez ', '50662486415', 'brisj10909m@gmail.com', '# documento 54210472\n19/3/2025', '24949541', '2025-03-24 02:39:07', 1, 0, NULL),
(109, 1, 15000.00, 42, 111, 'Panadería', 'CLIENTE', 'SISTEMA', '701910282 ', 'Ingrid Gutiérrez Rojas', '50688800148', 'ingridgr2022@gmail.com', '# documento 92892374\n19/3/2025', '92892374', '2025-03-24 02:40:38', 1, 0, NULL),
(110, 1, 15000.00, 16, 110, 'Decoración con globos - Nivel Básico ', 'CLIENTE', 'SISTEMA', '118720579', 'Karen García Quirós ', '50672416747', 'karengarciaquiross@gmail.com', '# documento 55901511\n19/3/2025', '15901511', '2025-03-24 02:42:31', 1, 0, NULL),
(111, 1, 15000.00, 25, 122, 'Vestidos de baño', 'CLIENTE', 'SISTEMA', '401480834', 'Ana Leticia Chaves Ramírez ', '50687292738', 'alei353@hotmail.com', 'BECADA', 'Becada', '2025-03-25 03:22:42', 1, 0, NULL),
(112, 1, 15000.00, 25, 122, 'Vestidos de baño', 'CLIENTE', 'SISTEMA', '401480834', 'Ana Leticia Chaves Ramírez ', '50687292738', 'alei353@hotmail.com', 'BECADA', 'Becada', '2025-03-25 03:22:50', 1, 0, NULL),
(113, 1, 15000.00, 38, 124, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '113830662', 'Mariela Rojas Calderón ', '50687681082', 'marie2489@gmail.com', '# DOCUMENTO 59478704\n21/3/2025', '958468895', '2025-03-25 03:28:14', 1, 0, NULL),
(114, 1, 15000.00, 38, 124, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '113830662', 'Mariela Rojas Calderón ', '50687681082', 'marie2489@gmail.com', '# DOCUMENTO 59478704\n21/3/2025', '958468895', '2025-03-25 03:28:27', 1, 0, NULL),
(115, 1, 15000.00, 49, 107, 'Barber Shop', 'CLIENTE', 'SISTEMA', '111620431', 'Guisela Murillo Cubero', '50671300518', 'guiselamurillo12@gmail.com', '# DOCUMENTO 54781006\n18/3/2025\n', '2025031810283006214781006', '2025-03-25 03:45:59', 1, 0, NULL),
(117, 1, 15000.00, 26, 173, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '401770098', 'Jenny Beatriz Zeledón Zúñiga', '50689161701', 'zeledonj09@yahoo.com', '', '98436505', '2025-03-31 15:03:40', 1, 0, NULL),
(118, 1, 15000.00, 26, 173, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '401770098', 'Jenny Beatriz Zeledón Zúñiga', '50689161701', 'zeledonj09@yahoo.com', '', '98436505', '2025-03-31 15:03:47', 1, 0, NULL),
(119, 1, 15000.00, 26, 174, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '401770098', 'Jenny Beatriz Zeledón Zúñiga', '50689161701', 'zeledonj09@yahoo.com', '', '98436505', '2025-03-31 15:09:51', 1, 0, NULL),
(120, 1, 15000.00, 26, 175, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '401280772', 'Patricia Chavarría Villegas', '50663953227', 'patriciach142@gmail.com', '', '2025033010283006285158267', '2025-03-31 15:16:43', 1, 0, NULL),
(121, 1, 15000.00, 27, 177, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '302600543', 'Leda Rodríguez Ruíz ', '50670151084', 'leroru04@gmail.com', '', '2025033110283006289202773', '2025-03-31 15:42:23', 1, 0, NULL),
(122, 1, 15000.00, 27, 183, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '402140567', 'Wendy Campos Rodríguez', '50670568174', 'wen.camp141@gmail.com', '', '2025033116183220535707066', '2025-03-31 20:56:57', 1, 0, NULL),
(123, 1, 15000.00, 27, 195, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '402350139', 'María Elena Ramírez Ramírez', '50689644084', 'mr84704@gmial.com', '', '95065689', '2025-04-02 20:03:25', 1, 0, NULL),
(124, 1, 15000.00, 31, 197, 'Quilting', 'CLIENTE', 'SISTEMA', '401070669', 'Ana Jane Camacho Soto', '50684416868', 'radiobarvacr@gmail.com', '', 'BECADA', '2025-04-02 20:33:15', 1, 0, NULL),
(125, 1, 15000.00, 14, 143, 'Almohadones, cojines y más - nivel pricipiante', 'CLIENTE', 'SISTEMA', '800460437', 'Cecilia Dolores Arauz Robleto', '50664790267', 'ceciarauz50@gmail.com', '', '04072881', '2025-04-02 21:24:15', 1, 0, NULL),
(126, 1, 15000.00, 16, 62, 'Decoración con globos - Nivel Básico ', 'CLIENTE', 'SISTEMA', '108270565 ', 'Patricia Ramírez Rimolo ', '50670395794', 'masiescara98@gmail.com', '', '2025031010283006162174131', '2025-04-02 21:40:34', 1, 0, NULL),
(127, 1, 15000.00, 28, 202, 'Bordado a mano', 'CLIENTE', 'SISTEMA', '401480881', 'Xinia Alfaro Bonilla', '50688788428', 'xaxalfaroo@gmail.com', 'BANCO CAJA DE ANDE\n03/04/2025', '2025040382183010357291432', '2025-04-03 16:19:01', 1, 0, NULL),
(128, 1, 15000.00, 28, 203, 'Bordado a mano', 'CLIENTE', 'SISTEMA', '204220150', 'María Patricia Conejo Rojas', '50689894536', 'patriciaconejo@hotmail.com', 'comprobante por 30 mil colones, dos cursos, bordado y costura y patronaje', '2025032582183010353624037', '2025-04-03 17:55:02', 1, 0, NULL),
(129, 1, 15000.00, 40, 209, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '106700550', 'Martha Elena Meléndez Monge', '50688206921', 'marthammonge@hotmail.com', 'Depósito el 04/04/2025', '6286422231', '2025-04-04 17:30:35', 1, 0, NULL),
(130, 1, 15000.00, 40, 209, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '106700550', 'Martha Elena Meléndez Monge', '50688206921', 'marthammonge@hotmail.com', 'Depósito el 04/04/2025', '6286422231', '2025-04-04 17:37:05', 1, 0, NULL),
(131, 1, 15000.00, 27, 210, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '120720203', 'Ariela Garita Flores', '50685384177', 'floreslucy08@gmail.com', 'Depósito 28632758 el 03/04/2025 por 30 mil colones, dos alumnas de costura desde cero, Ariela Garita Flores y Lucía Flores Fonseca', '28632758', '2025-04-04 17:46:36', 1, 0, NULL),
(132, 1, 15000.00, 27, 211, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '111260671', 'Lucía Flores Fonseca', '50688323567', 'floreslucy08@gmail.com', 'Depósito 28632758 el 03/04/2025 por 30 mil colones, dos alumnas de costura desde cero, Ariela Garita Flores y Lucía Flores Fonseca', '28632758', '2025-04-04 17:47:05', 1, 0, NULL),
(133, 1, 15000.00, 62, 212, 'Alambrismo y Bisutería - Nivel Intermedio', 'CLIENTE', 'SISTEMA', '401400554', 'Maribel Berrocal Miranda', '50688104611', 'mirandapalmamarielos@gmail.com', 'Depósito 2025040416183220542898083 el 04/04/2025 Banco Popular', '2025040416183220542898083', '2025-04-04 18:04:20', 1, 0, NULL),
(134, 1, 15000.00, 62, 213, 'Alambrismo y Bisutería - Nivel Intermedio', 'CLIENTE', 'SISTEMA', '401390551', 'Deyanira Castillo Chaves', '50684657497', 'deyacastillo2@gmail.com', 'BECADA', 'BECADA', '2025-04-04 18:07:04', 1, 0, NULL),
(135, 1, 15000.00, 15, 216, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '800460437', 'Cecilia Dolores Arauz Robleto', '50664790267', 'ceciarauz50@gmail.com', 'deposito el 25/03/2025 comprobante 04072881', '04072881', '2025-04-04 20:04:56', 1, 0, NULL),
(136, 1, 15000.00, 15, 216, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '800460437', 'Cecilia Dolores Arauz Robleto', '50664790267', 'ceciarauz50@gmail.com', 'deposito el 25/03/2025 comprobante 04072881', '04072881', '2025-04-04 20:07:40', 1, 0, NULL),
(137, 1, 15000.00, 25, 220, 'Vestidos de baño', 'CLIENTE', 'SISTEMA', '112440248', 'Susan Melissa Moya Sánchez', '50689122239', 'moyasanchezmelissa@gmail.com', '2025040580383010400157796\nbanco Davivienda el 05/04/2025', '2025040580383010400157796', '2025-04-07 17:53:10', 1, 0, NULL),
(138, 1, 15000.00, 19, 221, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '104130614', 'Flor María Cascante Fernández', '50688820390', 'fmcasf@gmail.com', '2025040610283006328573436\nbanco BAC EL 06/04/2025', '2025040610283006328573436', '2025-04-07 18:01:44', 1, 0, NULL),
(139, 1, 15000.00, 54, 222, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', '402540870', 'Melany Montero Rivera', '50661679051', 'melanymonterorivera@gmail.com', '2025040710283006334601324\nbanco BAC el 07/04/2025', '2025040710283006334601324', '2025-04-07 18:09:12', 1, 0, NULL),
(140, 1, 15000.00, 21, 223, 'Cosmética natural – avanzado (solamente quienes llevaron los 3 meses, enero a marzo 2025)', 'CLIENTE', 'SISTEMA', '701590004', 'Magaly Solorzano Guerrero', '50687518714', 'maga.gata35@gmail.com', '17294056\nbanco BN EL 03/04/2025', '17294056', '2025-04-07 18:15:21', 1, 0, NULL),
(141, 1, 15000.00, 21, 224, 'Cosmética natural – avanzado (solamente quienes llevaron los 3 meses, enero a marzo 2025)', 'CLIENTE', 'SISTEMA', '603820205', 'Andrea Vega Morales', '50689073506', 'keizu08@gmail.com', '15399127\nbanco BCR el 02/04/2025', '15399127', '2025-04-07 18:18:16', 1, 0, NULL),
(142, 1, 15000.00, 49, 226, 'Barber Shop', 'CLIENTE', 'SISTEMA', '122200475400', 'Silvia Orellana Díaz', '50662386651', 'orellanasilvia5050@gmail.com', '585236364\nbanco BN el 07/04/2025', '525236364', '2025-04-07 19:28:56', 1, 0, NULL),
(143, 1, 15000.00, 49, 227, 'Barber Shop', 'CLIENTE', 'SISTEMA', '122200041931', 'Bella Lorena Rivas Sosa', '50687645626', 'blrivassosa@gmail.com', '52311605\nbanco BCR el 07/04/2025', '52311605', '2025-04-07 19:34:27', 1, 0, NULL),
(144, 1, 15000.00, 49, 228, 'Barber Shop', 'CLIENTE', 'SISTEMA', '401740279', 'Jacqueline Gutiérrez Duarte', '50670196887', 'jackeline.g.d.81@gmail.com', '54639818\nbanco BCR el 07/04/2025', '54639818', '2025-04-08 14:14:01', 1, 0, NULL),
(145, 1, 15000.00, 25, 231, 'Vestidos de baño', 'CLIENTE', 'SISTEMA', '108860142', 'María Yael Solano Méndez', '50683133584', 'yaelita2806@gmail.com', '2025040715283006655368623\nbanco BN el 07/04/2025', '2025040715283006655368623', '2025-04-08 16:56:16', 1, 0, NULL),
(146, 1, 15000.00, 45, 71, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '113620824', 'Greidy Hernández Esteban ', '50670119590', 'greidy.hernandez@hotmail.com', 'PAGO DE MESNUALIDAD MAYO, EL 08/04/2025\nBANCO DAVIVIENDA 2025040880383010400954813', '2025040880383010400954813', '2025-04-08 17:10:59', 1, 0, NULL),
(147, 1, 15000.00, 26, 176, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '303400924', 'Yensy Meza Cortés', '50683083268', 'yensymeza22@gmail.com', '2025040710283006338147477\nbanco BAC el 07/04/2025', '2025040710283006338147477', '2025-04-08 17:25:13', 1, 0, NULL),
(148, 1, 15000.00, 26, 184, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '402040945', 'Daniela Arce Murillo', '50689911697', 'Danielaam2@hotmail.com', '2025040710283006338147477\nbanco BAC el 07/04/2025', '2025040710283006338147477', '2025-04-08 17:26:46', 1, 0, NULL),
(149, 1, 15000.00, 19, 234, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '112180858', 'Kimberly Lhamas Mohs', '50663089531', 'kimlhamasmohs@gmail.com', '59000036\nbanco BCR el 08/04/2025', '59000036', '2025-04-09 15:16:44', 1, 0, NULL),
(150, 1, 15000.00, 62, 235, 'Alambrismo y Bisutería - Nivel Intermedio', 'CLIENTE', 'SISTEMA', '115430513', 'Tracy Montero Mora', '50683891276', 'nanim264@gmail.com', '62585129\nbanco BCR el 08/04/2025 ', '62585129', '2025-04-09 16:07:40', 1, 0, NULL),
(151, 1, 15000.00, 64, 237, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '401960112', 'Priscilla Vargas González', '50683867509', 'prixi410@gmail.com', '2025040910283006344302972\nbanco BAC el 09/04/2025', '2025040910283006344302972', '2025-04-09 16:19:54', 1, 0, NULL),
(152, 1, 15000.00, 64, 225, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '402620221 ', 'Kristal Brillit León Orellana ', '50686420135', 'oreleonkriss80@gmail.com', '92637568\nbanco BN el 07/04/2025', '92637568', '2025-04-09 16:21:47', 1, 0, NULL),
(153, 1, 15000.00, 27, 238, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '401970264', 'Mariela Chaves Arias', '50685044046', 'chaves.mari.sr@gmail.com', '95176933\nbanco BN el 09/04/2025', '95176933', '2025-04-09 16:35:29', 1, 0, NULL),
(154, 1, 15000.00, 61, 198, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '402250682', 'Glenda Miranda Román', '50685634514', 'glenda.mr04@gmail.com', '2025040210283006304709081\nbanco BAC el 02/04/2025', '2025040210283006304709081', '2025-04-09 16:46:34', 1, 0, NULL),
(155, 1, 15000.00, 60, 239, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '108430014', 'Silvia Ramírez Zúñiga', '50672010885', 'sramirezz@yahoo.es', '94847930\nbanco BN el 08/04/2025', '94847930', '2025-04-10 16:50:19', 1, 0, NULL),
(156, 1, 15000.00, 60, 240, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '402580327', 'Valery Rebeca Vargas Segura', '50685455802', 'valesegura341@gmail.com', '2025041010283006350229918\nbanco BAC el 10/04/2025', '2025041010283006350229918', '2025-04-10 16:53:01', 1, 0, NULL),
(157, 1, 15000.00, 62, 214, 'Alambrismo y Bisutería - Nivel Intermedio', 'CLIENTE', 'SISTEMA', '401400554', 'Maribel Berrocal Miranda', '50685969834', 'maribelberro@gmail.com', '2025040416183220542898083\nBanco Popular el 04/04/2025', '2025040416183220542898083', '2025-04-10 17:09:06', 1, 0, NULL),
(158, 1, 15000.00, 18, 241, 'Costura y patronaje desde cero', 'CLIENTE', 'SISTEMA', '106320197', 'Jeannette Chavarría Campos', '50661193507', 'jecacha17@hotmail.com', '2025041015283006670637486\nbanco BN EL 10/04/2025', '2025041015283006670637486', '2025-04-10 17:23:31', 1, 0, NULL),
(159, 1, 15000.00, 43, 242, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '402810689', 'Habraham Miranda Morales', '50661711537', 'estrellamoralesbrenes344@gmail.com', '91458526 \nbanco BN el 07/04/2025', '91458526', '2025-04-14 14:32:11', 1, 0, NULL),
(160, 1, 15000.00, 23, 243, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '115770102', 'Catalina Vargas Hernández', '50687233561', 'cata07vh@gmail.com', '2025041010283006351844413\nbanco BAC el 10/04/2025', '2025041010283006351844413', '2025-04-14 15:25:01', 1, 0, NULL),
(161, 1, 15000.00, 38, 244, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '115770102', 'Catalina Vargas Hernández', '50687233561', 'cata07vh@gmail.com', '2025041010283006351824178\nbanco BAC el 10/04/2025', '2025041010283006351824178', '2025-04-14 15:27:45', 1, 0, NULL),
(162, 1, 15000.00, 64, 245, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '155826823226', 'Eveling Juniette Suazo Romero', '50685997639', 'juniethsuazo@gmail.com', '99615201\nbanco BN el 12/04/2025', '99615201', '2025-04-14 15:47:43', 1, 0, NULL),
(163, 1, 15000.00, 42, 248, 'Panadería', 'CLIENTE', 'SISTEMA', '155813950517', 'Erika Isabel López Mejía', '50688617062', 'lopezmejiaerika8@gmail.com', '11172869', '11172869', '2025-04-14 16:07:01', 1, 0, NULL),
(164, 1, 15000.00, 43, 249, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '104740370', 'Martha León López', '50670815196', 'marthalelop@gmail.com', '50090364 \nbanco BN el 24/03/2025', '50090365', '2025-04-14 16:25:49', 1, 0, NULL),
(165, 1, 15000.00, 44, 250, 'Repostería', 'CLIENTE', 'SISTEMA', '108760100', 'Leticia Villalobos Ramírez', '50683379728', 'lvillalobos032@hotmail.com', '16294702\nbanco BN el 10/04/2025', '16294702', '2025-04-14 16:29:21', 1, 0, NULL),
(166, 1, 15000.00, 31, 251, 'Quilting', 'CLIENTE', 'SISTEMA', '900640223', 'Elieth Sánchez Chaves', '50688958810', 'macha2631@gmail.com', '2025041410283006371749536 \nbanco BAC el 14/04/2025', '2025041410283006371749536', '2025-04-14 16:58:54', 1, 0, NULL),
(167, 1, 15000.00, 31, 253, 'Quilting', 'CLIENTE', 'SISTEMA', '134000227829', 'Verónica Dubón Vanegas', '50688831870', 'facturaciondigital2020gmail.com', '92272009\nbanco BN el 14/04/2025', '92272009', '2025-04-14 17:27:13', 1, 0, NULL),
(168, 1, 15000.00, 64, 254, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '401690527', 'Karla Marcela Campos Cortés', '50664561271', 'kc411292@gmail.com', '96725179\nbanco BCR el 14/04/2025', '96725179', '2025-04-14 18:36:23', 1, 0, NULL),
(169, 1, 15000.00, 61, 246, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '401780380', 'Flordeliz Vega Alavarado', '50663126760', 'fvega2354@gmail.com', '04069651 el 06/02/2025 BN por un monto de 30 mil colones, meses: marzo y abril', '04069651', '2025-04-14 18:44:33', 1, 0, NULL),
(170, 1, 15000.00, 61, 246, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '401780380', 'Flordeliz Vega Alavarado', '50663126760', 'fvega2354@gmail.com', '04074115 el 09/04/2025 por 15 mil colones, mes de mayo', '04074115', '2025-04-14 18:46:15', 1, 0, NULL),
(171, 1, 15000.00, 35, 255, 'Canva - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '402290565', 'Kassandra Arias Lindor', '50685505319', 'ariaslindork@gmail.com', '97520060 \nbanco BCR el 14/04/2025', '97520060', '2025-04-14 18:52:12', 1, 0, NULL),
(172, 1, 15000.00, 18, 256, 'Costura y patronaje desde cero', 'CLIENTE', 'SISTEMA', '204220150', 'María Patricia Conejo Rojas', '50689894536', 'patriciaconejo@hotmail.com', '2025032582183010353624037', '2025032582183010353624037', '2025-04-14 21:11:17', 1, 0, NULL),
(173, 1, 15000.00, 15, 207, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '110970348', 'Karina Esquivel Solano ', '50685491849', 'kriness@gmail.com', '50216261 \nel 04/04/2025', '50216261', '2025-04-14 21:36:33', 1, 0, NULL),
(174, 1, 15000.00, 16, 109, 'Decoración con globos - Nivel Básico ', 'CLIENTE', 'SISTEMA', '110590914', 'Katherine Siles Madrigal', '50683119972', 'kathysilesm20@gmail.com', '92875642 \nel 09/03/2025', '92875642', '2025-04-14 21:37:53', 1, 0, NULL),
(175, 1, 15000.00, 16, 150, 'Decoración con globos - Nivel Básico ', 'CLIENTE', 'SISTEMA', '402390755', 'Pamela Álvarez ', '50684206680', 'pamelaalvrz04@gmail.com', '2025032610283006256190875 \nel 26/03/2025', '2025032610283006256190875', '2025-04-14 21:38:51', 1, 0, NULL),
(176, 1, 15000.00, 17, 13, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '20482781', 'Carmen Murillo Espinoza', '50689873903', 'carmenmurilloespinoza@gmail.com', '20250307814830000600298728 el 07/03/2025', '20250307814830000600298728', '2025-04-14 21:39:54', 1, 0, NULL),
(177, 1, 15000.00, 17, 57, 'Decoración con Globos - Nivel Avanzado ', 'CLIENTE', 'SISTEMA', '109600558', 'Paola Vargas', '506', 'jpavazu@gmail.com', 'BECADA', 'BECADA', '2025-04-14 21:40:39', 1, 0, NULL),
(178, 1, 15000.00, 19, 83, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '113250320', 'Catalina Jiménez Ramírez', '50684984125', 'catalinajimenezr13@gmail.com', '6178816507 EL 13/03/2025', '6178816507', '2025-04-14 21:43:20', 1, 0, NULL),
(179, 1, 15000.00, 19, 108, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '10710-0406.', 'Ana Isabel Mora Romero', '50689165559', 'anita60mr@gmail.com', '6178816507 el 19/03/2025', ' Referencia 2025031915183010556767637.', '2025-04-14 21:44:02', 1, 0, NULL),
(180, 1, 15000.00, 19, 172, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '107440899', 'María Gabriela Frias Chaves', '50688804471', 'gabyfriaschaves@hotmail.com', '202503301528300659202510 el 31/03/2025', '202503301528300659202510', '2025-04-14 21:45:22', 1, 0, NULL),
(181, 1, 15000.00, 19, 182, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '602320635', 'Elsa Araya Chavarría ', '50688664541', 'elsaa2@gmail.com', '1471237 el 31/03/2025', '1471237', '2025-04-14 21:45:48', 1, 0, NULL),
(182, 1, 15000.00, 19, 182, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '602320635', 'Elsa Araya Chavarría ', '50688664541', 'elsaa2@gmail.com', '1471237 el 31/03/2025', '1471237', '2025-04-14 21:45:56', 1, 0, NULL),
(183, 1, 15000.00, 21, 186, 'Cosmética natural – avanzado (solamente quienes llevaron los 3 meses, enero a marzo 2025)', 'CLIENTE', 'SISTEMA', '119080280', 'Danna Paola Castillo Villalobos ', '50687490111', 'dannacastillov2004@gmail.com', '2025033110283006289730621 el 21/03/2025', '2025033110283006289730621', '2025-04-14 21:46:38', 1, 0, NULL),
(184, 1, 15000.00, 21, 187, 'Cosmética natural – avanzado (solamente quienes llevaron los 3 meses, enero a marzo 2025)', 'CLIENTE', 'SISTEMA', '109490626', 'Heisel Martinez Salgado', '50687437876', 'heisel120976@gmail.com', '91653776 el 31/03/2025', '91653776', '2025-04-14 21:47:09', 1, 0, NULL),
(185, 1, 15000.00, 19, 200, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '205470593', 'Lourdes mora soto', '50670521224', 'lourdesmorasoto@gmail.com', '58800066 el 02/04/2025', '58800066', '2025-04-14 21:48:20', 1, 0, NULL),
(186, 1, 15000.00, 19, 200, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '205470593', 'Lourdes mora soto', '50670521224', 'lourdesmorasoto@gmail.com', '58800066 el 02/04/2025', '58800066', '2025-04-14 21:48:27', 1, 0, NULL),
(187, 1, 15000.00, 19, 201, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', '402490573 ', 'Tatiana Villafuerte Retana ', '50660060595', 'tvillafuerte.04@outlook.com', '2025040310283006309601601 el 03/04/2025', '2025040310283006309601601', '2025-04-14 21:48:51', 1, 0, NULL),
(188, 1, 15000.00, 19, 218, 'Introducción a la cosmética natural', 'CLIENTE', 'SISTEMA', ' 106780125', 'Shirley Patricia Marín Muñoz ', '50683713717', 'shmarin13@hotmail.com', '90604492 el 07/04/2025', '90604492', '2025-04-14 21:49:13', 1, 0, NULL),
(189, 1, 15000.00, 22, 58, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '205050645', 'Diana Rojas Alpízar ', '50670872884', 'diana121075@hotmail.com', '2025030815283006437231217 el 10/03/2025', '2025030815283006437231217', '2025-04-14 22:04:50', 1, 0, NULL),
(190, 1, 15000.00, 22, 147, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '402370177', 'Stephanie Jiménez Lobo ', '50670566405', 'stephanie.m.jim@outlook.es', '91691152 el 25/03/2025', '91691152', '2025-04-14 22:06:40', 1, 0, NULL),
(191, 1, 15000.00, 22, 158, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '401730092 ', 'Guisselle Cambronero León ', '50686051200', 'gleon18@gmail.com', '51046001 el 27/03/2025', '51046001', '2025-04-14 22:07:40', 1, 0, NULL),
(192, 1, 15000.00, 22, 158, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '401730092 ', 'Guisselle Cambronero León ', '50686051200', 'gleon18@gmail.com', '51046001 el 27/03/2025', '51046001', '2025-04-14 22:13:19', 1, 0, NULL),
(193, 1, 15000.00, 35, 257, 'Canva - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '113380724', 'María José Sanabria Garro', '50683380999', 'mjsanabria03@gmail.com', '202504141028300637769048 el 14/04/2025 \nbanco BAC', '202504141028300637769048', '2025-04-14 22:21:32', 1, 0, NULL),
(194, 1, 15000.00, 23, 75, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '112780769', 'Doris Carolina Rodríguez Ramírez', '50683467785', 'dorys18@gmail.com', '56858218 el 12/03/2025', '56858218', '2025-04-14 22:27:51', 1, 0, NULL),
(195, 1, 15000.00, 23, 112, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '0117750879', 'Dayanna García Sánchez ', '50688920041', 'calicalderon09@gmail.com', '57799713 el 30/12/2024\nAlumna había matriculado amigurumi el primer trimestre del 2025 pero ese curso no se impartió, matricula maquillaje profesional para el segundo trimestre del 2025', '57799713', '2025-04-14 22:38:30', 1, 0, NULL),
(196, 1, 15000.00, 23, 112, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '0117750879', 'Dayanna García Sánchez ', '50688920041', 'calicalderon09@gmail.com', '57799713 el 30/12/2024\nAlumna había matriculado amigurumi el primer trimestre del 2025 pero ese curso no se impartió, matricula maquillaje profesional para el segundo trimestre del 2025', '57799713', '2025-04-14 22:38:36', 1, 0, NULL),
(197, 1, 15000.00, 23, 168, 'Maquillaje profesional ', 'CLIENTE', 'SISTEMA', '114850081', 'Grettel Barrios Barrientos ', '50662428017', 'grettelbarriosaj@gmail.com', '2025032810283006272233752 el 28/03/2025', '2025032810283006272233752', '2025-04-14 22:42:01', 1, 0, NULL),
(198, 1, 15000.00, 26, 139, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '115830332 ', 'Mónica Hernández Paniagua ', '50685589568', 'hernandezmoni22@hotmail.com', '28759405 el 21/03/2025', '28759405', '2025-04-14 22:50:34', 1, 0, NULL),
(199, 1, 15000.00, 26, 141, 'Costura básica desde cero - nivel intermedio ', 'CLIENTE', 'SISTEMA', '116680534', 'Pamela Quiros', '50660761584', 'pamelaquiros9712@gmail.com', '2025032410283006248573098 el 24/03/2025', '2025032410283006248573098', '2025-04-14 22:52:33', 1, 0, NULL),
(200, 1, 15000.00, 27, 97, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '402340174', 'Carmen Salazar Torres', '50686918249', 'cbeatriz1797@gmail.com', '2025032410283006248573098 el 17/03/2025', '2025031710283006206474137', '2025-04-14 23:02:57', 1, 0, NULL),
(201, 1, 15000.00, 27, 140, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '111490268', 'Yendry Miranda D', '50660509008', 'agosto2482@gmail.com', '2025032410283006248573098 el 24/03/2025', 'BAC 2025032410283006247806643', '2025-04-14 23:03:30', 1, 0, NULL),
(202, 1, 15000.00, 27, 144, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '108370010', 'Adriana Mora Fallas ', '50688311301', 'amorafa25@gmail.com', '91368032 el 25/03/2025', '91368032', '2025-04-14 23:04:08', 1, 0, NULL),
(203, 1, 15000.00, 27, 151, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '402240373', 'Dylan Arce Vargas ', '5067137653', 'dylavargas94@gmail.com', '202503261028300628432934 el 26/03/2025', '202503261028300628432934', '2025-04-14 23:04:51', 1, 0, NULL),
(204, 1, 15000.00, 27, 153, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '700520983', 'María Eugenia Gómez Ulloa ', '50664810588', 'marigu5477@gmail.com', '93443179 el 26/03/2025', '93443179', '2025-04-14 23:05:28', 1, 0, NULL),
(205, 1, 15000.00, 27, 156, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '112130362', 'Ana Victoria López Sánchez ', '50685837681', 'lopesanchezvictoriana@gmail.com', '94159969 el 27/03/2025', '94159969 BN', '2025-04-14 23:06:02', 1, 0, NULL),
(206, 1, 15000.00, 27, 167, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '402040464', 'Marianella Eduarte Rodríguez', '50671526228', 'nelaer221189@gmail.com', '2025032816183220530180186 el 28/03/2025', '2025032816183220530180186', '2025-04-14 23:06:39', 1, 0, NULL),
(207, 1, 15000.00, 27, 169, 'Costura básica desde cero - nivel básico', 'CLIENTE', 'SISTEMA', '113620190', 'MELANY AGUILAR ARGUELLO', '50685643372', 'melanytatiana88@gmail.com', '53059090 el 28/03/2025', '53059090', '2025-04-14 23:07:16', 1, 0, NULL),
(208, 1, 15000.00, 28, 96, 'Bordado a mano', 'CLIENTE', 'SISTEMA', '106330197', 'Silvia Ruiz Hernandez ', '50683547496', 'majorh_123@outlook.com', '99579184 el 17/03/2025', '99579184', '2025-04-14 23:11:45', 1, 0, NULL),
(209, 1, 15000.00, 28, 103, 'Bordado a mano', 'CLIENTE', 'SISTEMA', '107510249', 'Marjorie Ruiz Hernandez ', '50683547496', 'majorh_123@outlook.com', '91165854 el 18/03/2025', '91165854', '2025-04-14 23:12:20', 1, 0, NULL),
(210, 1, 15000.00, 32, 59, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '119810016', 'Tiffany Ramírez Leitón ', '50686881003', 'tiffarl10@gmail.com', '50966157 el 10/03/2025', '50966157', '2025-04-14 23:14:57', 1, 0, NULL),
(211, 1, 15000.00, 32, 61, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '108060527', 'Marcela Arce Espinoza', '50686677561', 'marcearceespinoza@gmail.com', '55028719 el 10/03/2025', '55028719', '2025-04-14 23:15:27', 1, 0, NULL),
(212, 1, 15000.00, 32, 79, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '402870905', 'Sharon Gustavina Arce ', '50685574353', 'alelobo4060@gmail.com', '2025031310283006176865521 el 13/03/2025', '2025031310283006176865521', '2025-04-14 23:16:18', 1, 0, NULL),
(213, 1, 15000.00, 32, 104, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '402760839', 'Alanis Camila Arce Lobo ', '50660649951', 'arcecamila730@gmail.com', '53915764 el 18/03/2025', '53915764', '2025-04-14 23:17:36', 1, 0, NULL),
(214, 1, 15000.00, 32, 155, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '701730020', 'Ingrid gabriela Mena Matarrita', '50684780456', 'gabymena045@gmail.com', '2025032710283006261196346 el 27/03/2025', '2025032710283006261196346', '2025-04-14 23:27:33', 1, 0, NULL),
(215, 1, 15000.00, 32, 159, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '402730901', 'Amanda Picado Espinoza ', '50672380699', 'emi.picado06@gmail.com', '56523621 el 27/03/2025', '56523621 ', '2025-04-14 23:28:10', 1, 0, NULL),
(216, 1, 15000.00, 32, 189, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '402610041', 'Nayeli Susana Soto calvo ', '50664054636', 'nayelissoto049@gmail.com', '2025033110283006291832613 el 31/03/2025', '2025033110283006291832613', '2025-04-14 23:28:50', 1, 0, NULL),
(217, 1, 15000.00, 35, 129, 'Canva - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '106790295', 'Jessica Montero Morales', '50660407375', 'jemonteromorales@gmail.com', '53698413 el 24/03/2025', '53698413', '2025-04-14 23:29:35', 1, 0, NULL),
(218, 1, 15000.00, 35, 138, 'Canva - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '401750832 ', 'Yancy Villalobos ', '50685966794', 'yancyvch21@gmail.com', '50740403 el 24/03/2025', '50740403', '2025-04-14 23:30:05', 1, 0, NULL),
(219, 1, 15000.00, 37, 130, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '106790295', 'Jessica Montero Morales ', '50660407375', 'jemonteromorales@gmail.com', '53694326 el 24/03/2025', '53694326', '2025-04-14 23:32:46', 1, 0, NULL),
(220, 1, 15000.00, 37, 134, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '115400953', 'Andrea León López ', '50672082849', 'andylopstar15@gmail.com', '50035716 el 24/03/2025', '50035716', '2025-04-14 23:33:14', 1, 0, NULL),
(221, 1, 15000.00, 37, 135, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '107160047', 'Mónica Albonico Araya', '50689824740', 'monicalbonico@gmail.com', '2025032410283006247156837 el 24/03/2025', '2025032410283006247156837', '2025-04-14 23:33:53', 1, 0, NULL),
(222, 1, 15000.00, 37, 148, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '401860689 ', 'Silvia Vargas Hernández ', '50685473391', 'mivanpri24@gmail.com', '57161273 el 25/03/2025', '57161273 ', '2025-04-14 23:34:26', 1, 0, NULL),
(223, 1, 15000.00, 37, 157, 'Creación de contenido para redes sociales', 'CLIENTE', 'SISTEMA', '107370254 ', 'Ligia María Varela Muñoz ', '50688057888', 'vivivarela68@gmail.com', 'BECADA', 'BECADA ', '2025-04-14 23:34:44', 1, 0, NULL),
(224, 1, 15000.00, 38, 124, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '113830662', 'Mariela Rojas Calderón ', '50687681082', 'marie2489@gmail.com', '59478704', '59478704', '2025-04-14 23:35:19', 1, 0, NULL),
(225, 1, 15000.00, 38, 125, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '604600552', 'Hazel Argüello Guerrero', '50685862323', 'hazelarguelloguerrero27@gmail.com', '2025032110283006230046602 el 21/03/2025', '2025032110283006230046602', '2025-04-14 23:36:04', 1, 0, NULL),
(226, 1, 15000.00, 38, 149, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '114160446', 'Adriana Solano', '50683082659', 'adri31sc@gmail.com', '92261965 el 25/03/2025', '92261965', '2025-04-14 23:36:37', 1, 0, NULL),
(227, 1, 15000.00, 39, 119, 'Curso básico de panadería', 'CLIENTE', 'SISTEMA', '401380433', 'Yamileth Arce Barquero', '50683391283', 'yarcebarquero@gmail.com', 'BECADA', 'BECADA', '2025-04-14 23:36:55', 1, 0, NULL),
(228, 1, 15000.00, 40, 85, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '502200753', 'Ligia Brenes Elizondo', '50688102040', 'ligia.bre@gmail.com', '55366055 EL 13/03/2025', '55366055', '2025-04-14 23:38:27', 1, 0, NULL),
(229, 1, 15000.00, 40, 163, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '155802404327', 'Kelly Jexabell Sequeira Areas', '50661295332', 'kelly.s.areas94@gmail.com', '20250302480383010395140783 el 24/03/2025', '20250302480383010395140783', '2025-04-14 23:39:07', 1, 0, NULL),
(230, 1, 15000.00, 40, 208, 'Alambrismo y Bisutería - Nivel Principiante', 'CLIENTE', 'SISTEMA', '401620477', 'Ileana Cordero León', '50685468134', 'ilecorleo@yahoo.com', '95564391', '95564391', '2025-04-14 23:39:40', 1, 0, NULL),
(231, 1, 15000.00, 42, 60, 'Panadería', 'CLIENTE', 'SISTEMA', '401940089', 'José Mario Valerio Berrocal ', '50684553578', 'jvalerio419@gmail.com', '98764280 el 10/03/2025', '98764280', '2025-04-16 22:28:01', 1, 0, NULL),
(232, 1, 15000.00, 42, 164, 'Panadería', 'CLIENTE', 'SISTEMA', '402480522', 'Josseline Daniela Jiménez Rodríguez', '50661039812', 'josseline649@gmail.com', '57347418 el 28/03/2025', '57347418 ', '2025-04-16 22:29:34', 1, 0, NULL),
(233, 1, 15000.00, 42, 191, 'Panadería', 'CLIENTE', 'SISTEMA', '106210599', 'Lorena Cubillo Lobo ', '50688950020', 'lorenacubillo93@gmail', '93499377 el 01/04/2025', '93499377', '2025-04-16 22:35:04', 1, 0, NULL),
(234, 1, 15000.00, 32, 264, 'Manicure profesional', 'CLIENTE', 'SISTEMA', '116730814', 'Verónica Patricia Gudiel Solís', '50671927475', 'vgudiel662@gmail.com', '91010098 el 21/04/2025 \nbanco BN', '91010098', '2025-04-22 15:08:35', 1, 0, NULL),
(235, 1, 15000.00, 22, 265, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '107440899', 'María Gabriela Frias Chaves', '50688804471', 'gabyfriaschaves@hotmail.com', '2025041615283006712558190 el 17/04/2025 BN', '2025041615283006712558190', '2025-04-22 15:21:55', 1, 0, NULL),
(236, 1, 15000.00, 63, 266, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo martes 7 pm a 9 pm', 'CLIENTE', 'SISTEMA', '401880650', 'Ana Victoria Vásquez Anchía', '50661665281', 'avictoria85@gmail.com', '2025041810283006397849853 el 18/04/2025\nBanco BAC', '2025041810283006397849853', '2025-04-22 15:59:36', 1, 0, NULL),
(237, 1, 15000.00, 63, 267, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo martes 7 pm a 9 pm', 'CLIENTE', 'SISTEMA', '402330790', 'Evelyn Daniela Alfaro Fonseca', '50689689013', 'eve_alfaro@hotmail.com', '2025041910283006400942263 el 19/04/2025\nbanco BAC', '2025041910283006400942263', '2025-04-22 16:44:32', 1, 0, NULL),
(238, 1, 15000.00, 64, 268, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '155840672617', 'Diana Vanessa Jirón Dávila', '50672957820', 'dianavanessadavila@gmail.com', '2025042110283006409763995 EL 21/04/2025 banco BAC', '2025042110283006409763995', '2025-04-22 16:49:14', 1, 0, NULL),
(239, 1, 15000.00, 22, 269, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '401061096', 'Micaela Camacho Vargas', '50689110888', 'micaelacv13@gmail.com', '2025042215183010535376495 el 22/04/2025 BN', '2025042215183010535376495', '2025-04-22 18:08:24', 1, 0, NULL),
(240, 1, 3750.00, 67, 270, 'Corte básico y alta peluquería', 'CLIENTE', 'SISTEMA', '402550825', 'Abril Gabriela Vindas Castro', '50672868191', 'avindas2014@gmail.com', '92358421 el 22/04/2025 BN', '92358421', '2025-04-22 19:02:56', 1, 0, NULL),
(241, 1, 15000.00, 68, 271, 'Vitro mosáico', 'CLIENTE', 'SISTEMA', '402330457', 'Saily Sandoval Ramírez', '50683872688', 'sailysandovalr@gmail.com', 'BECADA', 'BECADA', '2025-04-22 22:22:29', 1, 0, NULL),
(242, 1, 15000.00, 49, 273, 'Barber Shop', 'CLIENTE', 'SISTEMA', '402820392', 'Adrián Pérez Mendoza', '50687347775', 'mendozamarbellys44@gmail.com', '92954518 el 22/04/2025 BN', '92954518', '2025-04-22 22:36:38', 1, 0, NULL),
(243, 1, 15000.00, 68, 272, 'Vitro mosáico', 'CLIENTE', 'SISTEMA', '301971133', 'Ana Ligia Monge Quesada', '50688356135', 'analigiamongeq@gmail.com', '2025041081483000620934621 el 10/04/2025\nCOOPENAE', '2025041081483000620934621 el 10/04/2025', '2025-04-23 16:21:54', 1, 0, NULL),
(244, 1, 15000.00, 43, 73, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '402210923', 'Valeria campos lobo', '50672041477', 'valecl2693@gmail.com', '2025031210283006170323281 el 12/03/2025 BN', '2025031210283006170323281', '2025-04-23 16:31:30', 1, 0, NULL),
(245, 1, 15000.00, 43, 84, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '800770707', 'Mercedes Manzanares Barahona', '50687922465', 'william.Bermudez.ramirez@gmail.com', '93775791 EL 14/03/2025 BN', '93775791', '2025-04-23 16:33:03', 1, 0, NULL),
(246, 1, 15000.00, 43, 120, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '401480554 ', 'Katthya Trejos Zamora', '50688831919', 'trejoskz68@gmail.com', '94553375 EL 20/03/2025 BN', '94553375', '2025-04-23 16:33:54', 1, 0, NULL),
(247, 1, 15000.00, 43, 160, 'Pastelería – nivel #1', 'CLIENTE', 'SISTEMA', '604640539', 'Thaylin Zúñiga León', '50684878814', 'zthay10@gmail.com', '55608362 el 25/03/2025 BN', '55608362', '2025-04-23 16:34:40', 1, 0, NULL),
(248, 1, 15000.00, 44, 30, 'Repostería', 'CLIENTE', 'SISTEMA', '1-1116-0992 ', 'María de los Ángeles Ríos Obando', '50671036841', 'anais2409@gmail.com', '55837035 EL 07/03/2025 BN', '55887035', '2025-04-23 16:35:39', 1, 0, NULL),
(249, 1, 15000.00, 44, 50, 'Repostería', 'CLIENTE', 'SISTEMA', '206690166', 'Catalina Sánchez Sánchez ', '50683345869', 'cata23ss@hotmail.com', '93862872 EL 07/03/2025 BN', '93862872', '2025-04-23 16:36:17', 1, 0, NULL),
(250, 1, 15000.00, 44, 55, 'Repostería', 'CLIENTE', 'SISTEMA', '603050700', 'Dayanna Aguilar Brenes ', '50688273519', 'dayannaa3@gmail.com', '2025030710283006145415484 EL 07/03/2025 BN', '2025030710283006145415484', '2025-04-23 16:37:37', 1, 0, NULL),
(251, 1, 15000.00, 44, 63, 'Repostería', 'CLIENTE', 'SISTEMA', '402370817', 'Masiel Escalante Ramírez ', '50663786607', 'masiescara98@gmail.com', '2025031015283006451844391 EL 10/03/2025 BN', '2025031015283006451844391', '2025-04-23 16:38:12', 1, 0, NULL),
(252, 1, 15000.00, 44, 142, 'Repostería', 'CLIENTE', 'SISTEMA', '402370245', 'Maria celeste Mena Sanabria ', '50672910923', 'celestems131@gmail.com', '2025032480383010395258065 EL 24/03/2025 BN', '2025032480383010395258065', '2025-04-23 16:40:25', 1, 0, NULL),
(253, 1, 15000.00, 44, 154, 'Repostería', 'CLIENTE', 'SISTEMA', '206520889', 'Betsabeth corea miranda', '50684183435', 'betsabeth2012@gmail.com', '2025032680383010395960772 EL 26/03/2025 BN', '2025032680383010395960772', '2025-04-23 16:41:01', 1, 0, NULL),
(254, 1, 15000.00, 44, 165, 'Repostería', 'CLIENTE', 'SISTEMA', '402200967', 'Adriana Durán Villalobos ', '50670157613', 'duranvillalobosadri@gmail.com', '2025032810283006270431086 EL 28/03/2025 BN', '2025032810283006270431086', '2025-04-23 16:41:36', 1, 0, NULL),
(255, 1, 15000.00, 44, 170, 'Repostería', 'CLIENTE', 'SISTEMA', '402390808', 'Fiorella Chacón Alpizar ', '50663741538', 'fiochacon10@hotmail.com', '52130084 EL 31/03/2025 BN', '52130084', '2025-04-23 16:42:23', 1, 0, NULL),
(256, 1, 15000.00, 45, 72, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '114540360', 'Gabriela Mata Gamboa ', '50689636300', 'gabrielamatag@outlook.com', '2025031110283006166498822 EL 11/03/2025 BN', '2025031110283006166498822', '2025-04-23 16:44:38', 1, 0, NULL),
(257, 1, 15000.00, 45, 74, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '401440460 ', 'Elodia Hernandez Vargas ', '50687830596', 'elo.her@hotmail.es', '60238490 EL 11/03/2025 BN', '60238490', '2025-04-23 16:45:12', 1, 0, NULL),
(258, 1, 15000.00, 45, 76, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '117830143', 'Karen Herrera Sandi', '50684158568', 'kherrera0520@gmail.com', '91266642 EL 12/03/2025 BN', '91266642', '2025-04-23 16:45:43', 1, 0, NULL),
(259, 1, 15000.00, 45, 95, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '401880312', 'Anayanci Hernandez ', '50688820808', 'yanci0723@gmail.com', '99381400 EL 17/03/2025 BN', '99381400', '2025-04-23 16:48:39', 1, 0, NULL),
(260, 1, 15000.00, 45, 102, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '108390723', 'Isabel Cristina Rosales Chavarría ', '50688238231', 'isabelrosales2910@hotmail.com', '2025031810283006210948662 EL 18/03/2025 BN', '2025031810283006210948662', '2025-04-23 16:49:24', 1, 0, NULL),
(261, 1, 15000.00, 45, 117, 'Pastelería – nivel #2', 'CLIENTE', 'SISTEMA', '113340646 ', 'Laura Ugalde Calvo ', '50672193934', 'lauugalde36@yahoo.com', '50956696 EL 18/03/2025 BN', '50956696', '2025-04-23 16:50:00', 1, 0, NULL),
(262, 1, 15000.00, 49, 101, 'Barber Shop', 'CLIENTE', 'SISTEMA', '4 0282 0851', 'Natalie Ramos Campos ', '50662912560', 'vivi.camposh@gmail.com', '90349978 EL 17/03/2025 BN', '90349978', '2025-04-23 16:50:42', 1, 0, NULL);
INSERT INTO `movimientosdinero` (`id`, `tipoMovimiento`, `monto`, `idCurso`, `idMatricula`, `NombreCurso`, `Envia`, `Recibe`, `CedulaClientePaga`, `NombreClientePaga`, `TelefonoclientePaga`, `EmailClientePaga`, `Notas`, `comprobante`, `fecha`, `sePagoPorcentaje`, `idPagoProfesor`, `idProfesor`) VALUES
(263, 1, 15000.00, 49, 152, 'Barber Shop', 'CLIENTE', 'SISTEMA', '801150817', 'Fabiola Ninoska Flores Taleno ', '50660632350', 'fabiolaflores18@gmail.com', '63916383 EL 26/03/2025 BN', '63916383', '2025-04-23 16:51:32', 1, 0, NULL),
(264, 1, 15000.00, 49, 179, 'Barber Shop', 'CLIENTE', 'SISTEMA', '402300929', 'Guadalupe concepción Hernández sandino ', '50672975223', 'lupitasandino41117@gmail.com', '50521057 EL 18/03/2025 BN', '50521057', '2025-04-23 16:52:10', 1, 0, NULL),
(265, 1, 15000.00, 49, 181, 'Barber Shop', 'CLIENTE', 'SISTEMA', '111900813', 'Geovanna Vanessa Córdoba Prendas ', '50686461346', 'g.vane081318@gmail.com', '91307527 EL 31/03/2025 BN', '91307527', '2025-04-23 16:52:39', 1, 0, NULL),
(266, 1, 15000.00, 54, 190, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', '401730092 ', 'Guisselle Cambronero León ', '50686051200', 'gleon18@gmail.com', '53119002 EL 11/03/2025 BN', '53119002', '2025-04-23 16:53:33', 1, 0, NULL),
(267, 1, 15000.00, 54, 199, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', '116280215', 'Marvin Andrei González Vargas ', '50687160815', 'marvin95112009@hotmail.com', '54662616 EL 25/03/2025 BN', '54662616', '2025-04-23 16:54:07', 1, 0, NULL),
(268, 1, 15000.00, 54, 204, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', 'E023105', 'Melissa García Rodríguez ', '50663038834', 'mr8012793@gmail.com', '2025040310283006310739693 EL 03/04/2025 BN', '2025040310283006310739693', '2025-04-23 16:57:45', 1, 0, NULL),
(269, 1, 15000.00, 54, 206, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', '401940399', 'Sussana Bolaños Villalobos ', '50664887766', 'mariakpuravida2018@gmail.com', '29375362 EL 04/04/2025', '29375362', '2025-04-23 16:59:25', 1, 0, NULL),
(270, 1, 15000.00, 54, 217, 'Barber shop - avanzado (solamente alumnos que llevaron el básico de enero a marzo del 2025)', 'CLIENTE', 'SISTEMA', '504370383', 'Marifer Estrada Altamirano ', '50664852116', 'estrada.altamirano20marifer@gmail.com', '55513638 EL 07/04/2025 BN', '55513638', '2025-04-23 16:59:59', 1, 0, NULL),
(271, 1, 15000.00, 60, 192, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '107500884', 'Yorleny Fernández ', '50685898621', 'darialexa99@gmail.com', '2025040280383010398683444 EL 02/04/2025 BN', '2025040280383010398683444', '2025-04-23 17:00:39', 1, 0, NULL),
(272, 1, 15000.00, 60, 193, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '401840532', 'Yaireth Arias Aguilar ', '50687385271', 'yary0584@gmail.com', '55644971 EL 02/04/2025 BN', '55644971', '2025-04-23 17:01:20', 1, 0, NULL),
(273, 1, 15000.00, 60, 229, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '111230176 ', 'Maribel Sánchez Azofeifa ', '50683996796', 'maribellsna@gmail.com', '58981262 EL 08/04/2025 BN', '58981262', '2025-04-23 17:01:54', 1, 0, NULL),
(274, 1, 15000.00, 65, 230, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '119880006', 'Giuliana Sophía Vargas Mendoza', '50660071602', 'vargasgiuliana1602@gmail.com', '937889590 EL 08/04/2025 BN', '937889590', '2025-04-23 17:04:49', 1, 0, NULL),
(275, 1, 15000.00, 66, 274, 'Costura básica desde cero - nivel intensivo', 'CLIENTE', 'SISTEMA', '114600452', 'Tamara Moreno Ureña', '50672901911', 'tamaramoreno26@hotmail.com', '20250407102830063366901772 EL 07/04/2025 BAC', '20250407102830063366901772', '2025-04-23 18:51:57', 1, 0, NULL),
(276, 1, 15000.00, 66, 252, 'Costura básica desde cero - nivel intensivo', 'CLIENTE', 'SISTEMA', '401690916', 'Yajaira Garro González', '50688268104', 'yayigarro@yahoo.com', '90639561 EL 12/04/2025 BN', '90639531 ', '2025-04-23 18:53:18', 1, 0, NULL),
(277, 1, 15000.00, 66, 275, 'Costura básica desde cero - nivel intensivo', 'CLIENTE', 'SISTEMA', '401860213', 'Maricel Acuña Marín', '50688709645', 'mari1126@hotmail.es', '2025042310283006420937167 el 23/04/2025 BAC', '2025042310283006420937167', '2025-04-23 18:59:03', 1, 0, NULL),
(278, 1, 15000.00, 61, 247, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '402340709', 'Zaray Chavez Ocampo', '50672609955', 'zaraychavesocampo@gmail.com', '2025032510283006250390701 el 25/03/2025 banco BAC', '2025032510283006250390701 el 25/03/2025 banco BAC', '2025-04-23 20:43:32', 1, 0, NULL),
(279, 1, 15000.00, 64, 259, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '114730485', 'Paola Solís Meza', '50662970706', 'jenepao460@gmail.com', '93990061 EL 15/04/2025 BN', '93990061', '2025-04-23 21:25:08', 1, 0, NULL),
(280, 1, 15000.00, 18, 263, 'Costura y patronaje desde cero', 'CLIENTE', 'SISTEMA', '108320445', 'María Delgado Calderón', '50672605455', 'maria.delg.7389@gmail.com', '20250416102183006386374575 el 16/04/2025 BAC', '20250416102183006386374575', '2025-04-23 21:33:21', 1, 0, NULL),
(281, 1, 15000.00, 64, 276, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '402190103', 'Catalina Campos Cortés', '50661127211', 'catalinacampos066@gmai.com', '94439633 EL 23/04/2025 BN', '94439633', '2025-04-23 21:57:48', 1, 0, NULL),
(282, 1, 15000.00, 64, 277, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '106360220', 'Ana Isabel Reyes Herra', '50683825341', 'anareyesherra@outlook.com', '2025041410283006374834194 POR 14 MIL Y 2025041410283006376453311 POR MIL EL 14/04/2025', '76453311 Y 74834191', '2025-04-23 22:16:04', 1, 0, NULL),
(283, 1, 3750.00, 67, 278, 'Corte básico y alta peluquería', 'CLIENTE', 'SISTEMA', '701670581', 'Yendry Díaz Valverde', '50663562510', 'yendrydiazv@gmail.com', '52353242 EL 23/04/2025 BCR', '52353242', '2025-04-23 22:24:37', 1, 0, NULL),
(284, 1, 15000.00, 61, 279, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '304260599', 'Karol Gómez Cortés', '50671675305', 'karo881414@gmail.com', '2025042310283006422305164 el 23/04/2025 BAC', '2025042310283006422305164', '2025-04-23 22:32:43', 1, 0, NULL),
(285, 1, 15000.00, 61, 280, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '402130665', 'María Fernanda Pérez Chavarría', '50688010207', 'fernanda23.23@hotmail.com', '2025040110283006300900811 el 01/04/2025 BAC', '2025040110283006300900811', '2025-04-23 22:45:23', 1, 0, NULL),
(286, 1, 15000.00, 66, 281, 'Costura básica desde cero - nivel intensivo', 'CLIENTE', 'SISTEMA', '114320172', 'Yareliz Alvardao Cambronero', '50686504693', 'yarelizac@hotmail.com', '52626964 el 23/04/2025 BCR', '52626964', '2025-04-23 23:01:45', 1, 0, NULL),
(287, 1, 15000.00, 65, 283, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '401970615', 'Dayana Alfaro Esquivel', '50672032960', 'daalfaroe@gmail.com', '95361436 el 24/04/2025 BN', '95361436', '2025-04-24 16:41:28', 1, 0, NULL),
(288, 1, 15000.00, 18, 282, 'Costura y patronaje desde cero', 'CLIENTE', 'SISTEMA', '700550620', 'Ana Isabel Cruz Cruz', '50687123608', 'casmanuel1@yahoo.com', 'FT25113M4B EL 23/04/2025 BANCO POPULAR', 'FT25113M4B', '2025-04-24 18:38:58', 1, 0, NULL),
(289, 1, 15000.00, 65, 284, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '402750635', 'Josebeth Arrieta Zúñiga', '50686084624', 'jojoarixx@gmail.com', '95663994 el 24/04/2025 BN', '95663994', '2025-04-24 20:14:51', 1, 0, NULL),
(290, 1, 15000.00, 38, 285, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '402360387', 'Cindy Gutiérrez Abarca', '50689525072', 'gutierreza.facturas@gmail.com', '2025042510283006430123177 el 25/04/2025 BAC', '2025042510283006430123177', '2025-04-25 14:14:09', 1, 0, NULL),
(291, 1, 15000.00, 65, 258, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '118080544', 'Nicole Brenes Solís', '50684130962', 'nicolbrso1204@gmail.com', '56418146 el 14/04/2025 BN', '56418146', '2025-04-25 14:21:50', 1, 0, NULL),
(292, 1, 15000.00, 65, 261, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '117850083', 'Nicole Melissa Solís Salgado', '50664723689', 'melissasolis0770@gmail.com', '52987285 el 15/04/2025 SCOTIABANK', '52987285', '2025-04-25 14:24:39', 1, 0, NULL),
(293, 1, 15000.00, 65, 262, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '402020212', 'Daniela María Oconitrillo Garita', '50688194962', 'daniocog@gmail.com', ' 50003691 el 15/04/2025 BCR', '50003691', '2025-04-25 14:27:08', 1, 0, NULL),
(294, 1, 15000.00, 63, 286, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo martes 7 pm a 9 pm', 'CLIENTE', 'SISTEMA', '111030051', 'Verónica Guevara Corrales ', '50688272555', 'veronik29@yahoo.com', '2025042416183220572360334 el 24/04/2025 BANCO POPULAR', '2025042416183220572360334', '2025-04-25 14:37:59', 1, 0, NULL),
(295, 1, 15000.00, 65, 287, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '110410474', 'Rose Miranda González', '50687058435', 'odontomundo@yahoo.com', '2025042410283006428599041 el 24/04/2025 BAC', '2025042410283006428599041', '2025-04-25 14:51:19', 1, 0, NULL),
(296, 1, 15000.00, 22, 288, 'Jabonería artesanal', 'CLIENTE', 'SISTEMA', '108080542', 'Gabriela Arce Rubí', '50689229987', 'garce0211@gmail.com', '96274494 el 24/04/2025 BN', '96274494', '2025-04-25 14:56:25', 1, 0, NULL),
(297, 1, 15000.00, 31, 289, 'Quilting', 'CLIENTE', 'SISTEMA', '104630531', 'Yamileth Ruíz Vargas', '50688606307', 'yami@transportes-chaves.com', '2025042415283006760598725 el 25/04/2025 BN', '2025042415283006760598725', '2025-04-25 16:11:20', 1, 0, NULL),
(298, 1, 15000.00, 65, 290, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo viernes de 10:30 am a', 'CLIENTE', 'SISTEMA', '116000228', 'María Fernanda Alvarado Jiménez', '50684503385', 'andreysolis8916@gmail.com', '96817312 el 25/04/2025 BN', '96817312 ', '2025-04-25 17:01:08', 1, 0, NULL),
(299, 1, 15000.00, 60, 194, 'Masaje terapéutico - nivel avanzado', 'CLIENTE', 'SISTEMA', '4-0180-0485 ', 'Milena Espinoza Rojas ', '50660565826', 'milenaer12@gmail.com', 'BECADA', 'BECADA', '2025-04-25 18:04:37', 1, 0, NULL),
(300, 1, 15000.00, 62, 291, 'Alambrismo y Bisutería - Nivel Intermedio', 'CLIENTE', 'SISTEMA', '401080393', 'María de los Ángeles Miranda Palma', '50688104611', 'mirandapalmamarielos@gmail.com', '99529242 el 12/04/2025 BN', '99529242', '2025-04-25 18:17:39', 1, 0, NULL),
(301, 1, 15000.00, 63, 260, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo martes 7 pm a 9 pm', 'CLIENTE', 'SISTEMA', '401990430', 'Susana Segura Cortés', '50688365492', 'susansc45@gmail.com', '94356295 EL 15/04/2025 BN', '94356295', '2025-04-25 18:22:29', 1, 0, NULL),
(302, 1, 15000.00, 64, 292, 'Manicure profesional - solamente quienes llevaron los 3 primeros meses - Grupo miércoles de 10:30 am', 'CLIENTE', 'SISTEMA', '402300619', 'Mariana Sánchez Paniagua', '50660049256', 'marisanchez-1996@hotmail.com', '63828454 el 25/04/2025 BCR', '63828454', '2025-04-25 20:38:06', 1, 0, NULL),
(303, 1, 15000.00, 70, 295, 'Corte básico y alta peluquería', 'CLIENTE', 'SISTEMA', '701670581', 'Yendry Díaz Valverde', '50663562510', 'yendrydiazv@gmail.com', '52353242 el 23/04/2025 BCR', '52353242', '2025-04-25 22:20:40', 1, 0, NULL),
(304, 1, 15000.00, 70, 294, 'Corte básico y alta peluquería', 'CLIENTE', 'SISTEMA', '402550825', 'Abril Gabriela Vindas Castro', '50672868191', 'avindas2014gmail.com', '92358424 el 22/04/2025 BN', '92358421', '2025-04-25 22:21:25', 1, 0, NULL),
(305, 1, 15000.00, 61, 297, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '155819996611', 'Gisela Espinoza Avelares', '50661675144', 'giseespinoza94@hotmail.com', '97443556 el 25/04/2025 BN', '97443556', '2025-04-25 22:38:03', 1, 0, NULL),
(306, 1, 15000.00, 61, 296, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '119950153', 'María Luisa Acosta Zárate', '50660142698', 'malua2007@gmail.com', '2025042510283006433666079 EL 25/04/2025 BN', '2025042510283006433666079', '2025-04-25 22:38:56', 1, 0, NULL),
(307, 1, 15000.00, 61, 298, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '401560689', 'Lourdes María Arce Espinoza', '50683043666', 'arcelourdes1@gmail.com', '97514544 el 25/04/2025 BN', '97514544', '2025-04-25 23:14:51', 1, 0, NULL),
(308, 1, 15000.00, 61, 299, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', 'C03828961', 'Graciela Carolina Medrano Aburto', '50672669943', 'medranograciela156@gmail.com', '2025042810283006447736860 el 28/04/2025 BAC', '2025042810283006447736860', '2025-04-28 20:34:23', 1, 0, NULL),
(309, 1, 23000.00, 71, 300, 'Inglés - profe Jacqueline Guzmán', 'CLIENTE', 'SISTEMA', '401320083', 'María de los Ángeles Hernández Hernández', '50685461917', 'marieloshernandez086@gmail.com', 'BECADA', 'BECADA', '2025-04-28 22:35:36', 1, 0, NULL),
(310, 1, 23000.00, 71, 301, 'Inglés - profe Jacqueline Guzmán', 'CLIENTE', 'SISTEMA', '109590444', 'Ana Jiménez Arroyo', '50688897595', 'infogrupoakara@gmail.com', '2025042810283006453321436 el 28/04/2025 BAC', '2025042810283006453321436', '2025-04-29 14:56:57', 1, 0, NULL),
(311, 1, 15000.00, 70, 302, 'Corte básico y alta peluquería', 'CLIENTE', 'SISTEMA', '401740279', 'Jacqueline Gutiérrez Duarte', '50670196887', 'jackeline.g.d.81qgmail.com', '88950544 el 29/04/2025 BCR', '88950544', '2025-04-29 15:12:38', 1, 0, NULL),
(312, 1, 15000.00, 61, 303, 'Maquillaje profesional nivel 2', 'CLIENTE', 'SISTEMA', '402800481', 'Samantha Araya Jiménez', '50663771187', 'saudyjisa87@otlook.es', '88369722 el 28/04/2025 BCR', '88369722', '2025-04-29 16:30:50', 1, 0, NULL),
(313, 1, 15000.00, 44, 64, 'Repostería', 'CLIENTE', 'SISTEMA', '303750678', 'Vanessa Rodríguez Serrano ', '50661481859', 'vrs3981@hotmail.com', 'BECADA', 'BECADA', '2025-04-29 17:48:23', 1, 0, NULL),
(314, 1, 15000.00, 38, 304, 'Portugués - principiantes (virtual)', 'CLIENTE', 'SISTEMA', '604470170', 'Joselin Chen Chaves ', '50687239696', 'joselynchen24@gmail.com', '98837537 EL 02/05/2025', '98837537', '2025-05-02 21:10:52', 1, 0, NULL),
(315, 1, 0.00, 15, 121, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '2 462 507', 'Xinia Arguedas Vega ', '50671435344', 'xiniarguedas45@gmail.com', '15000', 'dqwd', '2025-05-04 08:21:47', 1, 0, NULL),
(316, 1, 0.00, 15, 121, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '2 462 507', 'Xinia Arguedas Vega ', '50671435344', 'xiniarguedas45@gmail.com', '15000', 'dqwd', '2025-05-04 08:22:01', 1, 0, NULL),
(317, 1, 0.00, 15, 121, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '2 462 507', 'Xinia Arguedas Vega ', '50671435344', 'xiniarguedas45@gmail.com', '15000', 'dqwd', '2025-05-04 08:24:29', 1, 0, NULL),
(318, 1, 0.00, 15, 121, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '2 462 507', 'Xinia Arguedas Vega ', '50671435344', 'xiniarguedas45@gmail.com', '15000', 'dqwd', '2025-05-04 08:24:46', 1, 0, NULL),
(319, 1, 0.00, 15, 207, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '110970348', 'Karina Esquivel Solano ', '50685491849', 'kriness@gmail.com', '15000', '50216261', '2025-05-04 09:31:59', 0, 0, NULL),
(320, 1, 15000.00, 15, 207, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '110970348', 'Karina Esquivel Solano ', '50685491849', 'kriness@gmail.com', 'PRUEBAS', '50216261', '2025-05-04 09:38:00', 0, 0, NULL),
(321, 1, 15000.00, 15, 216, 'Almohadones, cojines y más – Nivel intermedio - avanzado', 'CLIENTE', 'SISTEMA', '800460437', 'Cecilia Dolores Arauz Robleto', '50664790267', 'ceciarauz50@gmail.com', '', 'PRUEBNWESQWEFQef', '2025-05-04 09:38:32', 0, 0, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `movimientosdineroprofesores`
--

CREATE TABLE `movimientosdineroprofesores` (
  `id` int(11) NOT NULL,
  `tipoMovimiento` tinyint(4) NOT NULL,
  `monto` decimal(10,2) NOT NULL,
  `idCurso` int(11) NOT NULL,
  `idProfesor` int(11) NOT NULL,
  `Notas` text DEFAULT NULL,
  `comprobante` varchar(100) DEFAULT NULL,
  `fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `movimientosdineroprofesores`
--

INSERT INTO `movimientosdineroprofesores` (`id`, `tipoMovimiento`, `monto`, `idCurso`, `idProfesor`, `Notas`, `comprobante`, `fecha`) VALUES
(16, 2, 52500.00, 38, 1, '1231231231', '123123', '2025-05-04 08:28:05'),
(17, 2, 67500.00, 49, 2, '2312312', '1231', '2025-05-04 08:28:15'),
(18, 2, 45000.00, 54, 2, '', '', '2025-05-04 08:28:28');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `profesores`
--

CREATE TABLE `profesores` (
  `ID` int(11) NOT NULL,
  `NombreProfesor` varchar(100) NOT NULL,
  `Correo` varchar(100) NOT NULL,
  `Telefono` varchar(15) DEFAULT NULL,
  `Cedula` varchar(15) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `profesores`
--

INSERT INTO `profesores` (`ID`, `NombreProfesor`, `Correo`, `Telefono`, `Cedula`) VALUES
(1, 'Raquel Campos Chavarría', 'reunice.cha@gmail.com', '63634327', '401910222'),
(2, 'Pablo Álvarez Leitón', 'pabloa_2690@hotmail.com', '70664754', '402080280'),
(3, 'Lidieth Ramírez Chavarría', 'ldthramirez@gmail.com', '87251720', '105140811'),
(4, 'Kimberly Solís Gamazo', 'kimberly.solis.gamazo@gmail.com', '64010034', '112540960'),
(5, 'Lucy Alfaro Vega', 'lucyalfaro13@gmail.com', '86610084', '108440532'),
(6, 'Ligia Varela Víquez', 'vivivarela68@gmail.com', '88057888', '107370254'),
(7, 'Sadie Alvarado Miranda', 'sadiealvaradomiranda04@gmail.com', '87366578', '401380422'),
(8, 'Ariana Álvarez Arguedas', 'ariana31086@hotmail.com', '88741010', '112930816'),
(9, 'Ana Patricia Monge Bonilla', 'patricia2357@outlook.es', '83948747', '105980500'),
(10, 'Diana Rojas Alpízar', 'diana121075@hotmail.com', '70872884', '205050645'),
(11, 'Dorcas Pérez Cisneros', 'yayita61.25@gmail.com', '86197534', '900780944'),
(12, 'Kendry González Chanto', 'kendrygonzalezchacon@gmail.com', '71209131', '118240258'),
(13, 'Jacqueline Guzmán Arguedas ', 'bjaguar64@gmail.com', '89375828', '401370591'),
(14, 'Leidy Céspedes Murillo', 'cespedesmu01@hotmail.com', '83563091', '401970473'),
(15, 'Lizbeth Víquez Salas', 'l_viquez12@hotmail.com', '87489015', '401630071'),
(16, 'Luisa Gutiérrez Pardo', 'luisagutierrezpardo@hotmail.com', '83506991', '117002187304'),
(17, 'Marielos Artavia Fernández', 'fernandezartavia65@gmail.com', '84384390', '302800134'),
(18, 'Melissa Solano Rodríguez', 'melissasolano8628@gmail.com', '71381440', '112920450'),
(19, 'Michael Quesada Fernández', 'metanoicacs07@gmail.com', '72820107', '112250473'),
(20, 'Selphine Royal Dunn', 'selari2602@gmail.com', '89912008', '113070525'),
(21, 'Silvia Vargas Hernández', 'mivanpri24@gmail.com', '85473391', '401860689'),
(22, 'Ana Jiménez Arroyo', 'infogrupoakara@gmail.com', '88897595', '109590444'),
(23, 'Rocío Salas Cortés', 'rocio.salas.cortes@icloud.com', '83780023', '401480051'),
(24, 'Karolina Arguedas Salazar', 'karo.217495@gmail.com', '85311400', '108820958'),
(25, 'Ariana Ramírez Garro', 'arirg92@hotmail.com', '86994397', '115050398'),
(27, 'Sylvia Chaves Morales', 'schavesm@gmail.com', '83232470', '109010943'),
(28, 'Iris Muñóz Vargas', 'irismu07@gmail.com', '87530788', '303220656');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `roles`
--

CREATE TABLE `roles` (
  `ID` int(11) NOT NULL,
  `RoleName` varchar(50) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `roles`
--

INSERT INTO `roles` (`ID`, `RoleName`, `Description`, `IsActive`) VALUES
(1, 'Administrador', 'Rol con acceso completo a todas las funcionalidades del sistema', b'1'),
(2, 'Servicio al cliente', 'Rol encargado de gestionar las consultas y soporte a los clientes', b'1'),
(3, 'Contable', 'Rol responsable de la gestión financiera y contable del sistema', b'1'),
(4, 'Reporteria', 'Rol encargado de generar y gestionar los reportes del sistema', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sesiones`
--

CREATE TABLE `sesiones` (
  `IDSesion` int(11) NOT NULL,
  `UsuarioID` int(11) DEFAULT NULL,
  `TokenSesion` varchar(255) NOT NULL,
  `FechaInicio` datetime DEFAULT current_timestamp(),
  `FechaFin` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `sesiones`
--

INSERT INTO `sesiones` (`IDSesion`, `UsuarioID`, `TokenSesion`, `FechaInicio`, `FechaFin`) VALUES
(545, 2, '23c08005eb9d18bd4dfccd44cead528f', '2025-04-29 19:47:42', '2025-04-29 20:47:42'),
(574, 1, '53e8480ad0685ffec5d384b058aac693', '2025-05-04 09:45:06', '2025-05-04 18:45:06');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipomovimiento`
--

CREATE TABLE `tipomovimiento` (
  `id` int(11) NOT NULL,
  `descripcion` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `tipomovimiento`
--

INSERT INTO `tipomovimiento` (`id`, `descripcion`) VALUES
(1, 'Pago Recibido de cliente'),
(2, 'Pago a enviado a profesor');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `ID` int(11) NOT NULL,
  `Password` varchar(100) NOT NULL,
  `Email` varchar(100) NOT NULL,
  `FullName` varchar(100) DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`ID`, `Password`, `Email`, `FullName`, `IsActive`) VALUES
(1, '$2y$10$C.xCdCEJplB5HZBTeC35huJnJYmrpvMcGK17yfItnYSZDtssMahkO', 'desarrollo@cursomujerescr.com', 'Desarrollo', b'1'),
(2, '$2y$10$6iJ37VpoRnNdPO86FfBMwO20dt6HoWotUHAx3XWSL61K1yJ65OSo6', 'admin@cursomujerescr.com', 'Administrador General', b'1'),
(3, '$2y$10$s9.5ei/WUpItOcRggoBxa.GdBWSiErJmGEpHnzyqzT1JGu9n5g1Oa', 'servicio@cursomujerescr.com', 'Servicio al cliente', b'1'),
(4, '$2y$10$yyLAXhiZ79xOIl.VDTyh6utg.5V3gLe9aP5UJTwOlKUM8F3bluO/C', 'contabilidad@cursomujerescr.com', 'Contabilidad', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios_roles`
--

CREATE TABLE `usuarios_roles` (
  `UsuarioID` int(11) NOT NULL,
  `RoleID` int(11) NOT NULL,
  `AssignmentDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `usuarios_roles`
--

INSERT INTO `usuarios_roles` (`UsuarioID`, `RoleID`, `AssignmentDate`) VALUES
(1, 1, '2025-01-09 14:50:25'),
(1, 2, '2025-01-09 14:51:02'),
(1, 3, '2025-01-09 14:51:02'),
(1, 4, '2025-01-09 14:51:02'),
(2, 1, '2025-01-09 14:51:28'),
(2, 2, '2025-01-09 14:51:28'),
(2, 3, '2025-01-09 14:51:28'),
(2, 4, '2025-01-09 14:51:28'),
(3, 2, '2025-03-20 21:30:24'),
(3, 4, '2025-03-20 21:34:41'),
(4, 3, '2025-03-20 21:30:39'),
(4, 4, '2025-03-20 21:34:46');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vistacursosactivos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vistacursosactivos` (
`IdCurso` int(11)
,`NombreCurso` varchar(100)
,`Precio` decimal(10,2)
,`Descripcion` text
,`FechaInicio` date
,`FechaFin` date
,`ImagenCurso` varchar(255)
,`cupo_total` bigint(20) unsigned
,`cantidad_matriculas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vistacursosactivosv2`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vistacursosactivosv2` (
`IdCurso` int(11)
,`NombreCurso` varchar(100)
,`Precio` decimal(10,2)
,`Descripcion` text
,`FechaInicio` date
,`FechaFin` date
,`ImagenCurso` varchar(255)
,`cantidadCuotas` int(11)
,`cupo_total` bigint(20) unsigned
,`cantidad_matriculas` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_movimientos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_movimientos` (
`CONSECUTIVO` int(11)
,`TIPO_MOVIMIENTO` varchar(24)
,`MONTO` decimal(10,2)
,`NOMBRE_CURSO` varchar(100)
,`ID_MATRICULA` int(11)
,`ENVIA` varchar(255)
,`RECIBE` varchar(255)
,`CEDULA_CLIENTE_PAGA` varchar(45)
,`NOMBRE_CLIENTE_PAGA` varchar(45)
,`TELEFONO_CLIENTE_PAGA` varchar(45)
,`EMIAL_CLIENTE_PAGA` varchar(45)
,`NOTAS` varchar(255)
,`COMPROBANTE` varchar(100)
,`FECHA` datetime
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_movimientos_v2`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_movimientos_v2` (
`CONSECUTIVO` int(11)
,`TIPO_MOVIMIENTO` varchar(24)
,`MONTO` decimal(10,2)
,`NOMBRE_CURSO` varchar(100)
,`ID_MATRICULA` int(11)
,`ENVIA` varchar(255)
,`RECIBE` varchar(255)
,`CEDULA_CLIENTE_PAGA` varchar(45)
,`NOMBRE_CLIENTE_PAGA` varchar(45)
,`TELEFONO_CLIENTE_PAGA` varchar(45)
,`EMAIL_CLIENTE_PAGA` varchar(45)
,`NOTAS` varchar(255)
,`COMPROBANTE` varchar(100)
,`FECHA` datetime
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_profesores_pagos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_profesores_pagos` (
`nombre_profesor` varchar(100)
,`cedula_profesor` varchar(15)
,`correo_profesor` varchar(100)
,`total_monto_a_pagar` decimal(43,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_resumen_conta`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_resumen_conta` (
`cantidad_cursos_activos` bigint(21)
,`cantidad_matriculas` bigint(21)
,`matriculas_pendientes_cobro` bigint(21)
,`ingresos_confirmados` decimal(32,2)
,`pago_a_profesor` decimal(32,2)
,`ingresos_pendientes_cobro` decimal(33,2)
,`cantidad_desercion` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_resumen_conta_v2`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_resumen_conta_v2` (
`cantidad_cursos_activos` bigint(21)
,`cantidad_matriculas` bigint(21)
,`matriculas_pendientes_cobro` bigint(21)
,`ingresos_confirmados` decimal(33,2)
,`pago_a_profesor` decimal(32,2)
,`ingresos_pendientes_cobro` decimal(33,2)
,`cantidad_desercion` bigint(21)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_usuarios_roles`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_usuarios_roles` (
`UsuarioID` int(11)
,`Email` varchar(100)
,`FullName` varchar(100)
,`IsActive` bit(1)
,`Administrador` bigint(1)
,`Servicio_al_cliente` bigint(1)
,`Contable` bigint(1)
,`Reporteria` bigint(1)
);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `whatsapp_log`
--

CREATE TABLE `whatsapp_log` (
  `idRegistro` int(11) NOT NULL,
  `Envia` varchar(40) NOT NULL,
  `Recibe` varchar(40) NOT NULL,
  `Mensaje` varchar(100) NOT NULL,
  `FechaHora` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `whatsapp_log`
--

INSERT INTO `whatsapp_log` (`idRegistro`, `Envia`, `Recibe`, `Mensaje`, `FechaHora`) VALUES
(4, 'Sistema', '50685966794', 'Hola Yancy Villalobos . Hemos recibido su solicitud de matrícula, pronto le informaremos por este me', '2025-03-24 14:35:04'),
(5, 'Sistema', '50685589568', 'Hola Mónica Hernández Paniagua . Hemos recibido su solicitud de matrícula, pronto le informaremos po', '2025-03-24 14:44:46'),
(6, 'Sistema', '50660509008', 'Hola Yendry Miranda D. Hemos recibido su solicitud de matrícula, pronto le informaremos por este med', '2025-03-24 14:45:11'),
(7, 'Sistema', '50660761584', 'Hola Pamela Quiros. Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio ', '2025-03-24 16:54:57'),
(8, 'Sistema', '50672910923', 'Hola Maria celeste Mena Sanabria . Hemos recibido su solicitud de matrícula, pronto le informaremos ', '2025-03-24 17:12:10'),
(9, 'Sistema', '50664790267', 'Hola Cecilia Dolores Arauz Robleto. Hemos recibido su solicitud de matrícula, pronto le informaremos', '2025-03-25 10:01:53'),
(10, 'Sistema', '50688311301', 'Hola Adriana Mora Fallas . Hemos recibido su solicitud de matrícula, pronto le informaremos por este', '2025-03-25 10:05:21'),
(11, 'Sistema', '50684878814', 'Hola Thaylin Zúñiga . Hemos recibido su solicitud de matrícula, pronto le informaremos por este medi', '2025-03-25 12:07:11'),
(12, 'Sistema', '50683948747', 'Hola Patricia Monge Bonilla. Hemos recibido su solicitud de matrícula, pronto le informaremos por es', '2025-03-25 12:35:33'),
(13, 'Sistema', '50670566405', 'Hola Stephanie Jiménez Lobo . Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-03-25 13:30:50'),
(14, 'Sistema', '50685473391', 'Hola Silvia Vargas Hernández . Hemos recibido su solicitud de matrícula, pronto le informaremos por ', '2025-03-25 15:45:45'),
(15, 'Sistema', '50683082659', 'Hola Adriana Solano. Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio', '2025-03-25 19:31:03'),
(16, 'Sistema', '50684206680', 'Hola Pamela Álvarez . Hemos recibido su solicitud de matrícula, pronto le informaremos por este medi', '2025-03-26 09:24:50'),
(17, 'Sistema', '5067137653', 'Hola Dylan Arce Vargas . Hemos recibido su solicitud de matrícula, pronto le informaremos por este m', '2025-03-26 15:48:07'),
(18, 'Sistema', '50660632350', 'Hola Fabiola Ninoska Flores Taleno . Hemos recibido su solicitud de matrícula, pronto le informaremo', '2025-03-26 16:11:36'),
(19, 'Sistema', '50664810588', 'Hola María Eugenia Gómez Ulloa . Hemos recibido su solicitud de matrícula, pronto le informaremos po', '2025-03-26 17:27:30'),
(20, 'Sistema', '50684183435', 'Hola Betsabeth corea miranda. Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-03-26 17:42:57'),
(21, 'Sistema', '50684780456', 'Hola Ingrid gabriela Mena Matarrita. Hemos recibido su solicitud de matrícula, pronto le informaremo', '2025-03-27 08:36:05'),
(22, 'Sistema', '50685837681', 'Hola Ana Victoria López Sánchez . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-03-27 10:14:34'),
(23, 'Sistema', '50688057888', 'Hola Ligia María Varela Muñoz . Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-03-27 10:54:31'),
(24, 'Sistema', '50686051200', 'Hola Guisselle Cambronero León . Hemos recibido su solicitud de matrícula, pronto le informaremos po', '2025-03-27 13:05:21'),
(25, 'Sistema', '50672380699', 'Hola Amanda Picado Espinoza . Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-03-27 13:25:50'),
(26, 'Sistema', '50684878814', 'Hola Thaylin Zúñiga León. Hemos recibido su solicitud de matrícula, pronto le informaremos por este ', '2025-03-27 15:47:57'),
(27, 'Sistema', '506', 'Hola Marianella Eduarte Rodríguez. Hemos recibido su solicitud de matrícula, pronto le informaremos ', '2025-03-28 10:20:35'),
(28, 'Sistema', '50683948747', 'Hola Ana Patricia Monge Bonilla . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-03-28 12:27:46'),
(29, 'Sistema', '50661295332', 'Hola Kelly Jexabell Sequeira Areas. Hemos recibido su solicitud de matrícula, pronto le informaremos', '2025-03-28 12:44:19'),
(30, 'Sistema', '50661039812', 'Hola Josseline Daniela Jiménez Rodríguez. Hemos recibido su solicitud de matrícula, pronto le inform', '2025-03-28 14:59:38'),
(31, 'Sistema', '50670157613', 'Hola Adriana Durán Villalobos . Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-03-28 15:46:38'),
(32, 'Sistema', '50671526228', 'Hola Marianella Eduarte Rodríguez. Hemos recibido su solicitud de matrícula, pronto le informaremos ', '2025-03-28 18:01:27'),
(33, 'Sistema', '50671526228', 'Hola Marianella Eduarte Rodríguez. Hemos recibido su solicitud de matrícula, pronto le informaremos ', '2025-03-28 18:08:27'),
(34, 'Sistema', '50662428017', 'Hola Grettel Barrios Barrientos . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-03-28 18:38:43'),
(35, 'Sistema', '50685643372', 'Hola MELANY AGUILAR ARGUELLO. Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-03-28 19:50:49'),
(36, 'Sistema', '50663741538', 'Hola Fiorella Chacón Alpizar . Hemos recibido su solicitud de matrícula, pronto le informaremos por ', '2025-03-29 09:07:12'),
(37, 'Sistema', '50660331077', 'Hola Katthy Rodríguez Madrigal. Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-03-29 18:07:04'),
(38, 'Sistema', '50688804471', 'Hola María Gabriela Frias Chaves. Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-03-31 07:40:43'),
(39, 'Sistema', '50671435344', 'Hola Xinia Arguedas vega. Hemos recibido su solicitud de matrícula, pronto le informaremos por este ', '2025-03-31 11:26:49'),
(40, 'Sistema', '50672975223', 'Hola Guadalupe concepción Hernández sandino . Hemos recibido su solicitud de matrícula, pronto le in', '2025-03-31 11:54:42'),
(41, 'Sistema', '50688617062', 'Hola Erika Isabel Lopez Mejia. Hemos recibido su solicitud de matrícula, pronto le informaremos por ', '2025-03-31 12:08:06'),
(42, 'Sistema', '50686461346', 'Hola Geovanna Vanessa Córdoba Prendas . Hemos recibido su solicitud de matrícula, pronto le informar', '2025-03-31 13:14:16'),
(43, 'Sistema', '50688664541', 'Hola Elsa Araya Chavarría . Hemos recibido su solicitud de matrícula, pronto le informaremos por est', '2025-03-31 14:17:51'),
(44, 'Sistema', '50687490111', 'Hola Danna Paola Castillo Villalobos . Hemos recibido su solicitud de matrícula, pronto le informare', '2025-03-31 15:14:02'),
(45, 'Sistema', '50687490111', 'Hola Danna Paola Castillo Villalobos . Hemos recibido su solicitud de matrícula, pronto le informare', '2025-03-31 15:16:45'),
(46, 'Sistema', '50687437876', 'Hola Heisel Martinez Salgado. Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-03-31 16:07:02'),
(47, 'Sistema', '50663212216', 'Hola Nayeli . Hemos recibido su solicitud de matrícula, pronto le informaremos por este medio cuando', '2025-03-31 16:24:14'),
(48, 'Sistema', '50664054636', 'Hola Nayeli Susana Soto calvo . Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-03-31 16:36:22'),
(49, 'Sistema', '50686051200', 'Hola Guisselle Cambronero León . Hemos recibido su solicitud de matrícula, pronto le informaremos po', '2025-03-31 18:00:33'),
(50, 'Sistema', '50688950020', 'Hola Lorena Cubillo Lobo . Hemos recibido su solicitud de matrícula, pronto le informaremos por este', '2025-04-01 14:55:41'),
(51, 'Sistema', '50685898621', 'Hola Yorleny Fernández . Hemos recibido su solicitud de matrícula, pronto le informaremos por este m', '2025-04-02 10:33:30'),
(52, 'Sistema', '50687385271', 'Hola Yaireth Arias Aguilar . Hemos recibido su solicitud de matrícula, pronto le informaremos por es', '2025-04-02 10:44:27'),
(53, 'Sistema', '50660565826', 'Hola Milena Espinoza Rojas . Hemos recibido su solicitud de matrícula, pronto le informaremos por es', '2025-04-02 11:11:23'),
(54, 'Sistema', '50685634514', 'Hola Glenda Miranda Román. Hemos recibido su solicitud de matrícula, pronto le informaremos por este', '2025-04-02 15:25:11'),
(55, 'Sistema', '50687160815', 'Hola Marvin Andrei González Vargas . Hemos recibido su solicitud de matrícula, pronto le informaremo', '2025-04-02 16:52:04'),
(56, 'Sistema', '50670521224', 'Hola Lourdes mora soto. Hemos recibido su solicitud de matrícula, pronto le informaremos por este me', '2025-04-03 08:58:30'),
(57, 'Sistema', '50660060595', 'Hola Tatiana Villafuerte Retana . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-04-03 10:11:34'),
(58, 'Sistema', '50663038834', 'Hola Melissa García Rodríguez . Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-04-03 13:28:36'),
(59, 'Sistema', '50687518714', 'Hola Magaly Solorzano Guerrero . Hemos recibido su solicitud de matrícula, pronto le informaremos po', '2025-04-04 06:16:46'),
(60, 'Sistema', '50664887766', 'Hola Sussana Bolaños Villalobos . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-04-04 08:39:30'),
(61, 'Sistema', '50685491849', 'Hola Karina Esquivel Solano . Hemos recibido su solicitud de matrícula, pronto le informaremos por e', '2025-04-04 10:28:06'),
(62, 'Sistema', '50664852116', 'Hola Marifer Estrada Altamirano . Hemos recibido su solicitud de matrícula, pronto le informaremos p', '2025-04-05 17:21:31'),
(63, 'Sistema', '50683713717', 'Hola Shirley Patricia Marín Muñoz . Hemos recibido su solicitud de matrícula, pronto le informaremos', '2025-04-05 20:00:09'),
(64, 'Sistema', '50688820390', 'Hola flor maria cascante Fernández. Hemos recibido su solicitud de matrícula, pronto le informaremos', '2025-04-06 12:33:07'),
(65, 'Sistema', '50686420135', 'Hola Kristal Brillit León Orellana . Hemos recibido su solicitud de matrícula, pronto le informaremo', '2025-04-07 13:02:03'),
(66, 'Sistema', '50683996796', 'Hola Maribel Sánchez Azofeifa . Hemos recibido su solicitud de matrícula, pronto le informaremos por', '2025-04-08 10:21:55'),
(67, 'Sistema', '50660071602', 'Hola Giuliana Sophía Vargas Mendoza. Hemos recibido su solicitud de matrícula, pronto le informaremo', '2025-04-08 10:31:49'),
(68, 'Sistema', '50663126760', 'Hola Flordeliz Vega Alavarado. Hemos recibido su solicitud de matrícula, pronto le informaremos por ', '2025-04-14 09:56:58'),
(69, 'Sistema', '50672609955', 'Hola Zaray Chavez Ocampo. Hemos recibido su solicitud de matrícula, pronto le informaremos por este ', '2025-04-14 09:59:51'),
(70, 'Sistema', '50688268104', 'Hola Yajaira Garro González. Hemos recibido su solicitud de matrícula, pronto le informaremos por es', '2025-04-14 11:09:50');

-- --------------------------------------------------------

--
-- Estructura para la vista `vistacursosactivos`
--
DROP TABLE IF EXISTS `vistacursosactivos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vistacursosactivos`  AS SELECT `c`.`ID` AS `IdCurso`, `c`.`NombreCurso` AS `NombreCurso`, `c`.`Precio` AS `Precio`, `c`.`Descripcion` AS `Descripcion`, `c`.`FechaInicio` AS `FechaInicio`, `c`.`FechaFin` AS `FechaFin`, `ci`.`urlImagen` AS `ImagenCurso`, cast(sum(`hc`.`cupo`) as unsigned) AS `cupo_total`, coalesce(`matriculas`.`cantidad_matriculas`,0) AS `cantidad_matriculas` FROM (((`cursos` `c` join `horarios_cursos` `hc` on(`c`.`ID` = `hc`.`IdCurso`)) left join `cursoimagen` `ci` on(`c`.`ID` = `ci`.`cursoID`)) left join (select `matriculas`.`IdCurso` AS `IdCurso`,count(`matriculas`.`Id`) AS `cantidad_matriculas` from `matriculas` group by `matriculas`.`IdCurso`) `matriculas` on(`matriculas`.`IdCurso` = `c`.`ID`)) WHERE `c`.`Activo` = '1' GROUP BY `c`.`ID`, `c`.`NombreCurso`, `c`.`Precio`, `c`.`Descripcion`, `c`.`FechaInicio`, `c`.`FechaFin`, `ci`.`urlImagen` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vistacursosactivosv2`
--
DROP TABLE IF EXISTS `vistacursosactivosv2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vistacursosactivosv2`  AS SELECT `c`.`ID` AS `IdCurso`, `c`.`NombreCurso` AS `NombreCurso`, `c`.`Precio` AS `Precio`, `c`.`Descripcion` AS `Descripcion`, `c`.`FechaInicio` AS `FechaInicio`, `c`.`FechaFin` AS `FechaFin`, `ci`.`urlImagen` AS `ImagenCurso`, `c`.`cantidadCuotas` AS `cantidadCuotas`, cast(sum(`hc`.`cupo`) as unsigned) AS `cupo_total`, coalesce(`matriculas`.`cantidad_matriculas`,0) AS `cantidad_matriculas` FROM (((`cursos` `c` join `horarios_cursos` `hc` on(`c`.`ID` = `hc`.`IdCurso`)) left join `cursoimagen` `ci` on(`c`.`ID` = `ci`.`cursoID`)) left join (select `matriculas`.`IdCurso` AS `IdCurso`,count(`matriculas`.`Id`) AS `cantidad_matriculas` from `matriculas` group by `matriculas`.`IdCurso`) `matriculas` on(`matriculas`.`IdCurso` = `c`.`ID`)) WHERE `c`.`Activo` = '1' GROUP BY `c`.`ID`, `c`.`NombreCurso`, `c`.`Precio`, `c`.`Descripcion`, `c`.`FechaInicio`, `c`.`FechaFin`, `ci`.`urlImagen`, `c`.`cantidadCuotas` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_movimientos`
--
DROP TABLE IF EXISTS `vista_movimientos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_movimientos`  AS SELECT `movimientosdinero`.`id` AS `CONSECUTIVO`, CASE WHEN `movimientosdinero`.`tipoMovimiento` = '1' THEN 'Pago Recibido de cliente' WHEN `movimientosdinero`.`tipoMovimiento` = '2' THEN 'Pago enviado a profesor' ELSE `movimientosdinero`.`tipoMovimiento` END AS `TIPO_MOVIMIENTO`, `movimientosdinero`.`monto` AS `MONTO`, `cursos`.`NombreCurso` AS `NOMBRE_CURSO`, `movimientosdinero`.`idMatricula` AS `ID_MATRICULA`, `movimientosdinero`.`Envia` AS `ENVIA`, `movimientosdinero`.`Recibe` AS `RECIBE`, `movimientosdinero`.`CedulaClientePaga` AS `CEDULA_CLIENTE_PAGA`, `movimientosdinero`.`NombreClientePaga` AS `NOMBRE_CLIENTE_PAGA`, `movimientosdinero`.`TelefonoclientePaga` AS `TELEFONO_CLIENTE_PAGA`, `movimientosdinero`.`EmailClientePaga` AS `EMIAL_CLIENTE_PAGA`, `movimientosdinero`.`Notas` AS `NOTAS`, CASE WHEN `movimientosdinero`.`comprobante` = '0' THEN 'EFECTIVO' ELSE `movimientosdinero`.`comprobante` END AS `COMPROBANTE`, `movimientosdinero`.`fecha` AS `FECHA` FROM (`movimientosdinero` left join `cursos` on(`movimientosdinero`.`idCurso` = `cursos`.`ID`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_movimientos_v2`
--
DROP TABLE IF EXISTS `vista_movimientos_v2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_movimientos_v2`  AS SELECT `movimientosdinero`.`id` AS `CONSECUTIVO`, CASE WHEN `movimientosdinero`.`tipoMovimiento` = '1' THEN 'Pago Recibido de cliente' WHEN `movimientosdinero`.`tipoMovimiento` = '2' THEN 'Pago enviado a profesor' ELSE `movimientosdinero`.`tipoMovimiento` END AS `TIPO_MOVIMIENTO`, `movimientosdinero`.`monto` AS `MONTO`, `cursos`.`NombreCurso` AS `NOMBRE_CURSO`, `movimientosdinero`.`idMatricula` AS `ID_MATRICULA`, `movimientosdinero`.`Envia` AS `ENVIA`, `movimientosdinero`.`Recibe` AS `RECIBE`, `movimientosdinero`.`CedulaClientePaga` AS `CEDULA_CLIENTE_PAGA`, `movimientosdinero`.`NombreClientePaga` AS `NOMBRE_CLIENTE_PAGA`, `movimientosdinero`.`TelefonoclientePaga` AS `TELEFONO_CLIENTE_PAGA`, `movimientosdinero`.`EmailClientePaga` AS `EMAIL_CLIENTE_PAGA`, `movimientosdinero`.`Notas` AS `NOTAS`, CASE WHEN `movimientosdinero`.`comprobante` = '0' THEN 'EFECTIVO' ELSE `movimientosdinero`.`comprobante` END AS `COMPROBANTE`, `movimientosdinero`.`fecha` AS `FECHA` FROM (`movimientosdinero` left join `cursos` on(`movimientosdinero`.`idCurso` = `cursos`.`ID`)) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_profesores_pagos`
--
DROP TABLE IF EXISTS `vista_profesores_pagos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_profesores_pagos`  AS SELECT `p`.`NombreProfesor` AS `nombre_profesor`, `p`.`Cedula` AS `cedula_profesor`, `p`.`Correo` AS `correo_profesor`, round(sum(`c`.`Precio` * (`c`.`PorcentajePagoProfe` / 100)),2) AS `total_monto_a_pagar` FROM (((`profesores` `p` join `horarios_cursos` `h` on(`p`.`ID` = `h`.`IdProfesor`)) join `cursos` `c` on(`h`.`IdCurso` = `c`.`ID`)) join `matriculas` `m` on(`m`.`IdCurso` = `c`.`ID` and `m`.`IdHorario` = `h`.`ID`)) WHERE `c`.`Activo` = 1 AND `m`.`estadoPago` = 'Pagado' GROUP BY `p`.`ID`, `p`.`NombreProfesor`, `p`.`Cedula`, `p`.`Correo` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_resumen_conta`
--
DROP TABLE IF EXISTS `vista_resumen_conta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_resumen_conta`  AS SELECT (select count(0) from `cursos` where `cursos`.`Activo` = 1) AS `cantidad_cursos_activos`, (select count(0) from `matriculas` where `matriculas`.`activa` = 1) AS `cantidad_matriculas`, (select count(0) from `matriculas` where `matriculas`.`estadoPago` = 'Pendiente' and `matriculas`.`activa` = 1) AS `matriculas_pendientes_cobro`, ifnull((select sum(cast(case when `md`.`tipoMovimiento` = 1 then `md`.`monto` when `md`.`tipoMovimiento` = 2 then -`md`.`monto` else 0 end as decimal(10,2))) from `movimientosdinero` `md`),0.00) AS `ingresos_confirmados`, ifnull((select sum(cast(`md`.`monto` as decimal(10,2))) from `movimientosdinero` `md` where `md`.`tipoMovimiento` = 2),0.00) AS `pago_a_profesor`, greatest(0.00,ifnull((select sum(cast(`c`.`Precio` as decimal(10,2))) from (`matriculas` `m` join `cursos` `c` on(`m`.`IdCurso` = `c`.`ID`)) where `m`.`activa` = 1),0.00) - ifnull((select sum(cast(`md`.`monto` as decimal(10,2))) from `movimientosdinero` `md` where `md`.`tipoMovimiento` = 1),0.00)) AS `ingresos_pendientes_cobro`, (select count(0) from `desercion`) AS `cantidad_desercion` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_resumen_conta_v2`
--
DROP TABLE IF EXISTS `vista_resumen_conta_v2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_resumen_conta_v2`  AS SELECT (select count(0) from `cursos` where `cursos`.`Activo` = 1) AS `cantidad_cursos_activos`, (select count(0) from `matriculas` where `matriculas`.`activa` = 1) AS `cantidad_matriculas`, (select count(0) from `matriculas` where `matriculas`.`estadoPago` = 'Pendiente' and `matriculas`.`activa` = 1) AS `matriculas_pendientes_cobro`, ifnull((select sum(cast(case when `md`.`tipoMovimiento` = 1 then `md`.`monto` when `md`.`tipoMovimiento` = 2 then -`md`.`monto` else 0 end as decimal(10,2))) from `movimientosdinero` `md`),0.00) - ifnull((select sum(cast(`mdp`.`monto` as decimal(10,2))) from `movimientosdineroprofesores` `mdp` where `mdp`.`tipoMovimiento` = 2),0.00) AS `ingresos_confirmados`, ifnull((select sum(cast(`mdp`.`monto` as decimal(10,2))) from `movimientosdineroprofesores` `mdp` where `mdp`.`tipoMovimiento` = 2),0.00) AS `pago_a_profesor`, greatest(0.00,ifnull((select sum(cast(`c`.`Precio` as decimal(10,2))) from (`matriculas` `m` join `cursos` `c` on(`m`.`IdCurso` = `c`.`ID`)) where `m`.`activa` = 1),0.00) - ifnull((select sum(cast(`md`.`monto` as decimal(10,2))) from `movimientosdinero` `md` where `md`.`tipoMovimiento` = 1),0.00)) AS `ingresos_pendientes_cobro`, (select count(0) from `desercion`) AS `cantidad_desercion` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_usuarios_roles`
--
DROP TABLE IF EXISTS `vista_usuarios_roles`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_usuarios_roles`  AS SELECT `u`.`ID` AS `UsuarioID`, `u`.`Email` AS `Email`, `u`.`FullName` AS `FullName`, `u`.`IsActive` AS `IsActive`, max(if(`ur`.`RoleID` = 1,1,0)) AS `Administrador`, max(if(`ur`.`RoleID` = 2,1,0)) AS `Servicio_al_cliente`, max(if(`ur`.`RoleID` = 3,1,0)) AS `Contable`, max(if(`ur`.`RoleID` = 4,1,0)) AS `Reporteria` FROM (`usuarios` `u` left join `usuarios_roles` `ur` on(`u`.`ID` = `ur`.`UsuarioID`)) GROUP BY `u`.`ID` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `bitacoria_clientes`
--
ALTER TABLE `bitacoria_clientes`
  ADD PRIMARY KEY (`CONSECUTIVO`),
  ADD UNIQUE KEY `CEDULA` (`CEDULA`);

--
-- Indices de la tabla `cursoimagen`
--
ALTER TABLE `cursoimagen`
  ADD PRIMARY KEY (`idImagen`),
  ADD KEY `cursoID` (`cursoID`);

--
-- Indices de la tabla `cursos`
--
ALTER TABLE `cursos`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `desercion`
--
ALTER TABLE `desercion`
  ADD PRIMARY KEY (`Id`);

--
-- Indices de la tabla `horarios_cursos`
--
ALTER TABLE `horarios_cursos`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `listapagosprofesor`
--
ALTER TABLE `listapagosprofesor`
  ADD PRIMARY KEY (`idPago`);

--
-- Indices de la tabla `matriculas`
--
ALTER TABLE `matriculas`
  ADD PRIMARY KEY (`Id`),
  ADD KEY `IdCurso` (`IdCurso`),
  ADD KEY `FK_IdHorario` (`IdHorario`);

--
-- Indices de la tabla `movimientosdinero`
--
ALTER TABLE `movimientosdinero`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tipoMovimiento` (`tipoMovimiento`);

--
-- Indices de la tabla `movimientosdineroprofesores`
--
ALTER TABLE `movimientosdineroprofesores`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `profesores`
--
ALTER TABLE `profesores`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Correo` (`Correo`),
  ADD UNIQUE KEY `Cedula_UNIQUE` (`Cedula`);

--
-- Indices de la tabla `roles`
--
ALTER TABLE `roles`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `RoleName` (`RoleName`);

--
-- Indices de la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD PRIMARY KEY (`IDSesion`),
  ADD KEY `UsuarioID` (`UsuarioID`);

--
-- Indices de la tabla `tipomovimiento`
--
ALTER TABLE `tipomovimiento`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Email_UNIQUE` (`Email`);

--
-- Indices de la tabla `usuarios_roles`
--
ALTER TABLE `usuarios_roles`
  ADD PRIMARY KEY (`UsuarioID`,`RoleID`),
  ADD KEY `RoleID` (`RoleID`);

--
-- Indices de la tabla `whatsapp_log`
--
ALTER TABLE `whatsapp_log`
  ADD PRIMARY KEY (`idRegistro`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `bitacoria_clientes`
--
ALTER TABLE `bitacoria_clientes`
  MODIFY `CONSECUTIVO` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=263;

--
-- AUTO_INCREMENT de la tabla `cursoimagen`
--
ALTER TABLE `cursoimagen`
  MODIFY `idImagen` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT de la tabla `cursos`
--
ALTER TABLE `cursos`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT de la tabla `desercion`
--
ALTER TABLE `desercion`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=58;

--
-- AUTO_INCREMENT de la tabla `horarios_cursos`
--
ALTER TABLE `horarios_cursos`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=83;

--
-- AUTO_INCREMENT de la tabla `listapagosprofesor`
--
ALTER TABLE `listapagosprofesor`
  MODIFY `idPago` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=205;

--
-- AUTO_INCREMENT de la tabla `matriculas`
--
ALTER TABLE `matriculas`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=305;

--
-- AUTO_INCREMENT de la tabla `movimientosdinero`
--
ALTER TABLE `movimientosdinero`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=323;

--
-- AUTO_INCREMENT de la tabla `movimientosdineroprofesores`
--
ALTER TABLE `movimientosdineroprofesores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `profesores`
--
ALTER TABLE `profesores`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `roles`
--
ALTER TABLE `roles`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `sesiones`
--
ALTER TABLE `sesiones`
  MODIFY `IDSesion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=575;

--
-- AUTO_INCREMENT de la tabla `tipomovimiento`
--
ALTER TABLE `tipomovimiento`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `whatsapp_log`
--
ALTER TABLE `whatsapp_log`
  MODIFY `idRegistro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cursoimagen`
--
ALTER TABLE `cursoimagen`
  ADD CONSTRAINT `cursoimagen_ibfk_1` FOREIGN KEY (`cursoID`) REFERENCES `cursos` (`ID`);

--
-- Filtros para la tabla `matriculas`
--
ALTER TABLE `matriculas`
  ADD CONSTRAINT `FK_IdHorario` FOREIGN KEY (`IdHorario`) REFERENCES `horarios_cursos` (`ID`),
  ADD CONSTRAINT `matriculas_ibfk_1` FOREIGN KEY (`IdCurso`) REFERENCES `cursos` (`ID`);

--
-- Filtros para la tabla `movimientosdinero`
--
ALTER TABLE `movimientosdinero`
  ADD CONSTRAINT `movimientosdinero_ibfk_1` FOREIGN KEY (`tipoMovimiento`) REFERENCES `tipomovimiento` (`id`);

--
-- Filtros para la tabla `sesiones`
--
ALTER TABLE `sesiones`
  ADD CONSTRAINT `sesiones_ibfk_1` FOREIGN KEY (`UsuarioID`) REFERENCES `usuarios` (`ID`) ON DELETE CASCADE;

--
-- Filtros para la tabla `usuarios_roles`
--
ALTER TABLE `usuarios_roles`
  ADD CONSTRAINT `usuarios_roles_ibfk_1` FOREIGN KEY (`UsuarioID`) REFERENCES `usuarios` (`ID`) ON DELETE CASCADE,
  ADD CONSTRAINT `usuarios_roles_ibfk_2` FOREIGN KEY (`RoleID`) REFERENCES `roles` (`ID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
