// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Naku {

    address constant WALLET_FONDEO = 0x2016A5D9dC1c2D0339eFB7939CffF8Fc486270c3;

    struct Participante {
        address wallet; 
        uint numTurno;
        bool haRecibido; 
    }

    struct Transaccion {
        address from;
        address to;
        uint monto;
        uint fecha;
    }

    struct Sala {
        string hashId;
        address anfitrion;
        uint montoAportar;
        uint montoTotalAportar;
        uint numeroRondas;
        uint rondaActual;
        uint fechaInicio;
        uint fechaFin;
        bool salaFinalizada;
        Participante[] participantes;
        Transaccion[] historialTransacciones;
    }

    mapping(string => Sala) private salas;
    string[] public listaSalas;

    function crearSala(
        string memory hashId,
        uint montoAportar,
        uint numeroRondas,
        address walletAnfitrion,
        uint numTurno
    ) public {
        require(salas[hashId].montoAportar == 0, "La sala ya existe");
        require(numeroRondas > 0, "El numero de rondas debe ser mayor a cero");

        Sala storage nuevaSala = salas[hashId];
        nuevaSala.hashId = hashId;
        nuevaSala.anfitrion = walletAnfitrion;
        nuevaSala.montoAportar = montoAportar;
        nuevaSala.montoTotalAportar = 0;
        nuevaSala.numeroRondas = numeroRondas;
        nuevaSala.rondaActual = 1;
        nuevaSala.fechaInicio = block.timestamp;
        nuevaSala.fechaFin = 0;
        nuevaSala.salaFinalizada = false;

        nuevaSala.participantes.push(Participante({
            wallet: walletAnfitrion,
            numTurno: numTurno,
            haRecibido: false
        }));

        listaSalas.push(hashId);
    }

    function agregarParticipante(
        string memory hashId,
        address wallet,
        uint numTurno
    ) public {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        require(!salas[hashId].salaFinalizada, "La sala ya esta finalizada");
        require(salas[hashId].participantes.length < salas[hashId].numeroRondas, "El limite de participantes ha sido alcanzado");

        Sala storage sala = salas[hashId];
        sala.participantes.push(Participante({
            wallet: wallet,
            numTurno: numTurno,
            haRecibido: false
        }));
    }

    function registrarTransaccion(
        string memory hashId,
        address from,
        address to,
        uint monto
    ) public {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        require(!salas[hashId].salaFinalizada, "La sala ya esta finalizada");
        require(monto > 0, "El monto debe ser mayor a cero");

        Sala storage sala = salas[hashId];
        sala.historialTransacciones.push(Transaccion({
            from: from,
            to: to,
            monto: monto,
            fecha: block.timestamp
        }));

        sala.montoTotalAportar += monto;
    }

    function realizarEnvio(string memory hashId, address walletParticipante) public {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        require(!salas[hashId].salaFinalizada, "La sala ya esta finalizada");

        Sala storage sala = salas[hashId];
        require(sala.montoTotalAportar >= sala.montoAportar * sala.participantes.length, "No se ha completado el monto total");

        for (uint i = 0; i < sala.participantes.length; i++) {
            if (sala.participantes[i].numTurno == sala.rondaActual && !sala.participantes[i].haRecibido) {
                require(sala.participantes[i].wallet == walletParticipante, "Wallet no coincide con el participante en turno");

                payable(sala.participantes[i].wallet).transfer(sala.montoAportar);
                sala.participantes[i].haRecibido = true;

                sala.historialTransacciones.push(Transaccion({
                    from: WALLET_FONDEO,
                    to: sala.participantes[i].wallet,
                    monto: sala.montoAportar,
                    fecha: block.timestamp
                }));

                if (sala.rondaActual == sala.numeroRondas) {
                    sala.fechaFin = block.timestamp;
                    sala.salaFinalizada = true;
                } else {
                    sala.rondaActual++;
                }
                break;
            }
        }
    }

    function obtenerSala(string memory hashId) public view returns (
        address anfitrion,
        uint montoAportar,
        uint montoTotalAportar,
        uint numeroRondas,
        uint rondaActual,
        uint fechaInicio,
        uint fechaFin,
        bool salaFinalizada
    ) {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        Sala storage sala = salas[hashId];
        return (
            sala.anfitrion,
            sala.montoAportar,
            sala.montoTotalAportar,
            sala.numeroRondas,
            sala.rondaActual,
            sala.fechaInicio,
            sala.fechaFin,
            sala.salaFinalizada
        );
    }

    function obtenerParticipantes(string memory hashId) public view returns (Participante[] memory) {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        return salas[hashId].participantes;
    }

    function obtenerHistorialTransacciones(string memory hashId) public view returns (Transaccion[] memory) {
        require(salas[hashId].montoAportar > 0, "La sala no existe");
        return salas[hashId].historialTransacciones;
    }
}