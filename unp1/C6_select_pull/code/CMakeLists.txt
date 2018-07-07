project(select_pull_sample)
include_directories("../../Code")
set(LIB_PATH "../../Code")
set(BASE_C ${LIB_PATH}/unp_base.c)

add_executable(makeBigFile makeBigFile.c)
#add_executable(server server.c ${BASE_C})
add_executable(client client.c ${BASE_C})
add_executable(client_shut client_shut.c ${BASE_C})

add_executable(server_good server_good.c ${BASE_C})
add_executable(server_select server_select.c ${BASE_C})
add_executable(server_pull server_pull.c ${BASE_C})
