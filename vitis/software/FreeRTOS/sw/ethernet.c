/******************************************************************************
* Copyright 2021 Sebastian Wendel, Eyke Liegmann
* 
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
* 
*     http://www.apache.org/licenses/LICENSE-2.0
* 
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and limitations under the License.
******************************************************************************/

#include <string.h>
#include "lwip/sockets.h"
#include "netif/xadapter.h"
#include "lwipopts.h"
#include "FreeRTOS.h"
#include "task.h"
#include "APU_RPU_shared.h"

#include "../main.h"

extern QueueHandle_t js_queue;
extern struct APU_to_RPU_t ControlData;

// Socket de la conexion ACTIVA con el scope (0 = ninguna). Lo lee el ISR (isr.c) para decidir si
// encola muestras. Solo hay una conexion valida: cuando el scope reconecta, la nueva se queda con
// esta variable y el hilo de la anterior, al despertar, ve que ya no es suya y termina sin tocarla.
volatile int js_connection_established = 0;
int i_LifeCheck_process_Ethernet = 0;

// Deteccion de conexiones muertas (enlace caido sin FIN/RST): keepalive TCP tras JS_KEEPALIVE_IDLE_S
// segundos sin trafico, JS_KEEPALIVE_CNT sondeos cada JS_KEEPALIVE_INTVL_S segundos. Los tiempos por
// socket requieren LWIP_TCP_KEEPALIVE=1 en el BSP (parametro lwip_tcp_keepalive del lwip211); sin
// el, SO_KEEPALIVE usa el valor por defecto de lwIP (2 horas).
#define JS_KEEPALIVE_IDLE_S		3
#define JS_KEEPALIVE_INTVL_S	1
#define JS_KEEPALIVE_CNT		3
// Tiempo maximo esperando la respuesta de 8 bytes del scope (requiere LWIP_SO_RCVTIMEO=1).
#define JS_RECV_TIMEOUT_MS		5000

static void js_configure_socket(int fd)
{
	int on = 1;
	lwip_setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on));
#if LWIP_TCP_KEEPALIVE
	int idle = JS_KEEPALIVE_IDLE_S, intvl = JS_KEEPALIVE_INTVL_S, cnt = JS_KEEPALIVE_CNT;
	lwip_setsockopt(fd, IPPROTO_TCP, TCP_KEEPIDLE, &idle, sizeof(idle));
	lwip_setsockopt(fd, IPPROTO_TCP, TCP_KEEPINTVL, &intvl, sizeof(intvl));
	lwip_setsockopt(fd, IPPROTO_TCP, TCP_KEEPCNT, &cnt, sizeof(cnt));
#endif
#if LWIP_SO_RCVTIMEO
#if LWIP_SO_SNDRCVTIMEO_NONSTANDARD
	int tmo = JS_RECV_TIMEOUT_MS;
#else
	struct timeval tmo = { JS_RECV_TIMEOUT_MS / 1000, (JS_RECV_TIMEOUT_MS % 1000) * 1000 };
#endif
	lwip_setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tmo, sizeof(tmo));
#endif
	lwip_setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &on, sizeof(on));
}

// Lee exactamente len bytes (TCP es un flujo: la respuesta podria llegar partida). <=0 = error/cierre.
static int js_read_exact(int fd, char *buf, int len)
{
	int got = 0;
	while (got < len) {
		int n = read(fd, buf + got, len - got);
		if (n <= 0)
			return n;
		got += n;
	}
	return got;
}


//==============================================================================================================================================================
void print_echo_app_header()
{
    mz_printf("%20s %6d %s\r\n", "echo server",
    			TCPPORT,
				"$ telnet <board_ip> 1000");
}

//==============================================================================================================================================================
/*---------------------------------------------------------------------------*
 * Routine:  process_request_thread
 *---------------------------------------------------------------------------*
 * Description:
 *      thread spawned for each connection  = tcpWorker
 *      This thread sends and receives the data, regarding the information
 *      in the shared RAM. This thread runs always!
 *---------------------------------------------------------------------------*/
void process_request_thread(void *p)
{
	struct javascope_data_t javascope_data_sending = {0};
	NetworkSendStruct nwsend = {0};
	struct APU_to_RPU_t received = {0};

	int clientfd = (int)p;
	int nread = 0;
	int nwrote = 0;

	mz_printf("APU: Javascope connected 0x%x\n", clientfd);
	js_configure_socket(clientfd);
	// Esta conexion pasa a ser la activa; si habia otra, su hilo terminara al ver que ya no lo es.
	js_connection_established = clientfd;

	xQueueReset(js_queue); //purge queue once new connection is established

	while (js_connection_established == clientfd) {

		for (size_t i=0; i<NETWORK_SEND_FIELD_SIZE; i++){

			// Take one element from queue
			// The maximum amount of time the task should block waiting for an item to receive should the queue be empty at the time of the call.
			xQueueReceive(js_queue, &javascope_data_sending, JS_QUEUE_RECEIVE_TICKS2WAIT);

			// copy data into nwsend struct
			nwsend.val_01[i] 	= javascope_data_sending.scope_ch[0];
			nwsend.val_02[i] 	= javascope_data_sending.scope_ch[1];
			nwsend.val_03[i] 	= javascope_data_sending.scope_ch[2];
			nwsend.val_04[i]  	= javascope_data_sending.scope_ch[3];
			nwsend.val_05[i]  	= javascope_data_sending.scope_ch[4];
			nwsend.val_06[i]  	= javascope_data_sending.scope_ch[5];
			nwsend.val_07[i] 	= javascope_data_sending.scope_ch[6];
			nwsend.val_08[i] 	= javascope_data_sending.scope_ch[7];
			nwsend.val_09[i] 	= javascope_data_sending.scope_ch[8];
			nwsend.val_10[i] 	= javascope_data_sending.scope_ch[9];
			nwsend.val_11[i]  	= javascope_data_sending.scope_ch[10];
			nwsend.val_12[i]  	= javascope_data_sending.scope_ch[11];
			nwsend.val_13[i]  	= javascope_data_sending.scope_ch[12];
			nwsend.val_14[i] 	= javascope_data_sending.scope_ch[13];
			nwsend.val_15[i] 	= javascope_data_sending.scope_ch[14];
			nwsend.val_16[i] 	= javascope_data_sending.scope_ch[15];
			nwsend.val_17[i] 	= javascope_data_sending.scope_ch[16];
			nwsend.val_18[i] 	= javascope_data_sending.scope_ch[17];
			nwsend.val_19[i] 	= javascope_data_sending.scope_ch[18];
			nwsend.val_20[i] 	= javascope_data_sending.scope_ch[19];
			nwsend.slowDataContent[i] 	= javascope_data_sending.slowDataContent;
			nwsend.slowDataID[i] 		= javascope_data_sending.slowDataID;
		}
		nwsend.status = javascope_data_sending.status;

		// Mientras esperabamos en la cola pudo entrar una conexion nueva: no enviar por esta.
		if (js_connection_established != clientfd)
			break;

		// At this point, Ethernet Package is full and ready to be sent
		i_LifeCheck_process_Ethernet++;
		if(i_LifeCheck_process_Ethernet > 2500){
			i_LifeCheck_process_Ethernet =0;
		}

		// write the data -> handle request /
		// The data is sent here
		if ((nwrote = write(clientfd, &nwsend, sizeof(nwsend))) <= 0) {
			mz_printf("APU: %s: ERROR responding to client echo request. received = %d, written = %d\r\n",
			__FUNCTION__, nread, nwrote);
			mz_printf("APU: Closing socket %d\r\n", clientfd);
			break;
		}

		// El scope contesta a cada paquete con exactamente un APU_to_RPU_t (8 bytes)
		nread = js_read_exact(clientfd, (char *)&received, sizeof(received));
		if (nread <= 0) {
			mz_printf("APU: %s: socket %d closed or timed out (%d), closing Javascope socket\r\n", __FUNCTION__, clientfd, nread);
			break;
		}
		if (js_connection_established != clientfd)
			break;	// conexion sustituida: el comando ya no es de la sesion activa
		ControlData.id 		= received.id;
		ControlData.value 	= received.value;
	}

	// close connection. Solo se "apaga" el scope si esta conexion sigue siendo la activa:
	// si ya hay una nueva, ponerlo a 0 dejaria a la nueva sin muestras (el ISR deja de encolar).
	taskENTER_CRITICAL();
	if (js_connection_established == clientfd)
		js_connection_established = 0;
	taskEXIT_CRITICAL();
	close(clientfd);
	mz_printf("APU: Javascope socket %d closed\r\n", clientfd);
	vTaskDelete(NULL);
}

//==============================================================================================================================================================
/*---------------------------------------------------------------------------*
 * Routine:  application_thread
 *---------------------------------------------------------------------------*
 * Description:
 *      This is the tcpHandler.
 *      Creates new Task to handle new TCP connections.
 *---------------------------------------------------------------------------*/
void application_thread()
{
	int sock;
	int new_clientfd;
	struct sockaddr_in address, remote;
	int size;

	if ((sock = lwip_socket(AF_INET, SOCK_STREAM, 0)) < 0)
		return;

	address.sin_family = AF_INET;
	address.sin_port = htons(TCPPORT);
	address.sin_addr.s_addr = INADDR_ANY;

	if (lwip_bind(sock, (struct sockaddr *)&address, sizeof (address)) < 0)
		return;

	lwip_listen(sock, 0);

	size = sizeof(remote);

	while (1) {
		size = sizeof(remote);
		if ((new_clientfd = lwip_accept(sock, (struct sockaddr *)&remote, (socklen_t *)&size)) > 0) {
			if (sys_thread_new("echos", process_request_thread,
				(void*)new_clientfd,
				THREAD_STACKSIZE,
				DEFAULT_THREAD_PRIO) == NULL) {
				mz_printf("APU: could not create Javascope thread, closing socket %d\r\n", new_clientfd);
				close(new_clientfd);
			}
		} else if (new_clientfd < 0) {
			// sin sockets libres u otro error: no quedarse en un bucle ocupado
			mz_printf("APU: accept failed\r\n");
			vTaskDelay(pdMS_TO_TICKS(500));
		}
	}
}
