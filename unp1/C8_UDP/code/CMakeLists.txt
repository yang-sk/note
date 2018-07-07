project(time_tcp)
include_directories("../../Code")
set(LIB_PATH "../../Code")
set(BASE_C ${LIB_PATH}/unp_base.c)

add_executable(server server.c ${BASE_C})
add_executable(client client.c ${BASE_C})
add_executable(client_2 client_2.c ${BASE_C})
add_executable(client_conn client_conn.c ${BASE_C})

add_executable(server_select server_select.c ${BASE_C})