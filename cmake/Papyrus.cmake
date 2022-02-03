#[=======================================================================[.rst:
Papyrus
-------

Compile Papyrus scripts

Usage:

.. code-block:: cmake

  add_papyrus(<target> GAME <game_path>
              IMPORTS <import> ...
              SOURCES <source> ...
              [OPTIMIZE] [ANONYMIZE])

Example:

.. code-block:: cmake

  add_papyrus(
    "Papyrus"
    GAME $ENV{Skyrim64Path}
    IMPORTS $ENV{SKSE64Path}/Scripts/Source
            ${CMAKE_CURRENT_SOURCE_DIR}/scripts
    SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script1.psc
            ${CMAKE_CURRENT_SOURCE_DIR}/scripts/MOD_Script2.psc
    OPTIMIZE ANONYMIZE)
#]=======================================================================]

function(add_papyrus PAPYRUS_TARGET)
	set(options OPTIMIZE ANONYMIZE)
	set(oneValueArgs GAME)
	set(multiValueArgs IMPORTS SOURCES)
	cmake_parse_arguments(PAPYRUS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	set(PAPYRUS_IMPORT_DIR "${PAPYRUS_GAME}/Data/Source/Scripts")
	set(PAPYRUS_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/Scripts")

	foreach(SOURCE IN ITEMS ${PAPYRUS_SOURCES})
		cmake_path(GET SOURCE STEM LAST_ONLY SOURCE_FILENAME)
		cmake_path(REPLACE_EXTENSION SOURCE_FILENAME LAST_ONLY "pex" OUTPUT_VARIABLE OUTPUT_FILENAME)
		cmake_path(APPEND PAPYRUS_OUTPUT_DIR "${OUTPUT_FILENAME}" OUTPUT_VARIABLE OUTPUT_FILE)
		list(APPEND PAPYRUS_OUTPUT ${OUTPUT_FILE})

		add_custom_command(
			OUTPUT ${OUTPUT_FILE}
			COMMAND "${PAPYRUS_GAME}/Papyrus Compiler/PapyrusCompiler.exe"
				${SOURCE}
				"-import=${PAPYRUS_IMPORTS};${PAPYRUS_IMPORT_DIR}"
				"-output=${PAPYRUS_OUTPUT_DIR}"
				"-flags=${PAPYRUS_IMPORT_DIR}/TESV_Papyrus_Flags.flg"
				"$<$<BOOL:${PAPYRUS_OPTIMIZE}>:-optimize>"
			DEPENDS ${SOURCE}
			VERBATIM
		)
	endforeach()

	if (PAPYRUS_ANONYMIZE)
		find_program(PEXANON_PATH AFKPexAnon PATHS "tools/AFKPexAnon")
		if(NOT PEXANON_PATH)
			set(PEXANON_DOWNLOAD "${CMAKE_CURRENT_BINARY_DIR}/download/AFKPexAnon-1.1.0-x64.7z")

			file(
				DOWNLOAD
				"https://github.com/namralkeeg/AFKPexAnon/releases/download/v1.1.0/AFKPexAnon-1.1.0-x64.7z"
				"${PEXANON_DOWNLOAD}"
				EXPECTED_HASH MD5=79d646d42bd4d5a1a4cfc63ef00d004a
				STATUS DOWNLOAD_STATUS
			)

			if(DOWNLOAD_STATUS)
				list(GET DOWNLOAD_STATUS 1 DOWNLOAD_ERROR)
				message(FATAL_ERROR "${DOWNLOAD_ERROR}")
			endif()

			file(
				ARCHIVE_EXTRACT
				INPUT "${PEXANON_DOWNLOAD}"
				DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/tools/AFKPexAnon"
			)

			set(PEXANON_PATH "${CMAKE_CURRENT_BINARY_DIR}/tools/AFKPexAnon/AFKPexAnon.exe")
		endif()

		# Anonymize command needs to be appended to the last command and depend on the rest
		set(ANONYMIZE_DEPENDS ${PAPYRUS_OUTPUT})
		list(POP_BACK ANONYMIZE_DEPENDS ANONYMIZE_OUTPUT)

		add_custom_command(
			OUTPUT ${ANONYMIZE_OUTPUT}
			DEPENDS ${ANONYMIZE_DEPENDS}
			COMMAND ${PEXANON_PATH}
				-s "${PAPYRUS_OUTPUT_DIR}"
			VERBATIM APPEND
		)
	endif()

	add_custom_target(
		"${PAPYRUS_TARGET}" ALL
		DEPENDS ${PAPYRUS_OUTPUT}
		SOURCES ${PAPYRUS_SOURCES}
	)

	set(PAPYRUS_OUTPUT ${PAPYRUS_OUTPUT} PARENT_SCOPE)
endfunction()
