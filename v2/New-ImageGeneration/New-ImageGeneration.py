import PySimpleGUI as sg
import requests
import json
import os
import subprocess

url_get_xl_models = "http://192.168.4.254:64640/sdapi/v1/sd-models"
url_get_sd_models = "http://localhost:64640/sdapi/v1/sd-models"
url_get_xlt_models = "http://localhost:64669/sdapi/v1/sd-models"

url_set_xl_models = "http://192.168.4.254:64640/sdapi/v1/options"
url_set_sd_models = "http://localhost:64640/sdapi/v1/options"
url_set_xlt_models = "http://localhost:64669/sdapi/v1/options"

selected_models = ""
instances_list = ("SD", "XL", "XLT")

if os.name == "nt":
	appicon = 'New-ImageGeneration.ico'
else:
	appicon = 'New-ImageGeneration.png'

# Boucle pour sélectionner tous les multiples de 8 entre 512 et 1920
multiples_de_8 = []
for i in range(512, 1921):
	if i % 8 == 0:
		multiples_de_8.append(i)

with open("../lists/samplers.txt", "r") as sampler_file:
	samplers_list = [line.strip() for line in sampler_file.readlines()]

with open("../lists/Styles.txt", "r") as styles_file:
	styles_list = [line.strip() for line in styles_file.readlines()]

with open("../lists/Artists.txt", "r") as artists_file:
	artists_list = [line.strip() for line in artists_file.readlines()]

with open("../lists/Direction.txt", "r") as direction_file:
	direction_keywords_list = [line.strip() for line in direction_file.readlines()]

with open("../lists/Conceptually.txt", "r") as conceptual_file:
	conceptual_keywords_list = [line.strip() for line in conceptual_file.readlines()]

with open("../lists/Mood.txt", "r") as mood_file:
	mood_keywords_list = [line.strip() for line in mood_file.readlines()]

sg.theme("DarkPurple2")

sg.set_options(text_justification="left")

layout = [
	[
		[sg.Text(
			"StableDiffusion API Generation Parameters", font=("Courier", 16, "bold")
		)],
		[sg.Submit("Générer l'image", pad=15, key='generate'),sg.FileBrowse('Sélectionner un template',pad=15,target='template_file'),sg.Input(key='template_file')],
		[sg.Button("Changer de checkpoint", pad=15, key='set_model')]
	],
	[
		sg.Column(
			[
				[
					sg.Frame(
						"Génération",
						[
								[
									sg.Text("Instance pour la génération", size=30),
									sg.Combo(instances_list, default_value='XL', size=4, key="instance", enable_events=True)
								],
								[sg.HorizontalSeparator(pad=5)],
								[
									sg.Text("Nombre d'images à générer", size=30),
									sg.Spin(
										[i for i in range(1, 100)],
										initial_value=1,
										size=4,
										key="nb_img",
									)],
								[sg.Text("Max = 100", font=("Courier", 11))],
								[sg.HorizontalSeparator(pad=5)],
								[sg.Text("Checkpoint", size=15)],
								[sg.Combo(selected_models, size=40, key="checkpoint")],
								[sg.HorizontalSeparator(pad=5)],
								[sg.Frame("Dimensions",
								[
									[
										sg.Text('Entre 512 et 1920',font=('Courier', 11))
									],
									[sg.Text("Largeur"),
									sg.Spin(
										values=multiples_de_8,
										size=5,
										initial_value=512,
										key="width"
									),
									sg.Text("Hauteur"),
									sg.Spin(
										values=multiples_de_8,
										size=5,
										initial_value=512,
										key="height"
									)]
							],
							border_width=3,
							relief="sunken",
							pad=5,
							font=("Courier", 14),
							vertical_alignment="top"
						)]
						],
						border_width=3,
						relief="sunken",
						pad=5,
						font=("Courier", 14),
						vertical_alignment="top"
					),
				]
			]
		),
			sg.Column(
			[
					[
						sg.Frame(
							"Paramètres",
							[
									[
										sg.Column(
											[
													[
														sg.Text("Sampler", size=10),
														sg.Combo(
															samplers_list,
															size=30,
															default_value="DPM++ 2M Karras",
															key="sampler",
														),
													],
													[sg.HorizontalSeparator(pad=5)],
													[
														sg.Text("Seed", size=10),
														sg.Input(
															size=25, default_text="-1", key="seed"
														),
													],
													[
														sg.Text(
															"Entre 1 et 2^32 ou -1 = Aléatoire",
															font=("Courier", 11),
														)
													],
													[sg.HorizontalSeparator(pad=5)],
													[
														sg.Text("Attention", size=15),
														sg.Spin(
															[i for i in range(3, 30)],
															initial_value=6,
															size=4,
															key="attention",
														)],
														[sg.Text(
															"Entre 3 et 30",
															font=("Courier", 11),
														)],
													[sg.HorizontalSeparator(pad=5)],
													[
														sg.Text("Étapes", size=15),
														sg.Spin(
															[i for i in range(20, 150)],
															initial_value=20,
															size=4,
															key="steps",
														)],
														[sg.Text(
															"Entre 20 et 150",
															font=("Courier", 11),
														)
													],
													[sg.HorizontalSeparator(pad=5)],
													[sg.Text("Face Restore", size=15),
													sg.Checkbox("", key="restore_faces")],
											],
											vertical_alignment="top",
											pad=5,
										)
									]
							],
							border_width=3,
							relief="sunken",
							pad=5,
							font=("Courier", 14),
							vertical_alignment="top"
						)
					]
			],
			vertical_alignment="top",
			pad=5,
		)
	],
	[
	sg.Column(
			[
				[
				sg.Frame(
				"Choix Artistiques",
				[
					[
						sg.Text("Style de l'image", size=20),
						sg.Combo(
							styles_list,
							key="style",
							default_value="Random",
							size=20,
						),
						sg.Text("Direction artistique", size=20),
						sg.Combo(
							direction_keywords_list, key="direction", size=20
						),
					],
					[
							sg.Frame(
								"Artistes",
								[
										[sg.Combo(artists_list, key="artist1", size=25),
										sg.Combo(artists_list, key="artist2", size=25),
										sg.Combo(artists_list, key="artist3", size=25)]
								],
								border_width=3,
								relief="sunken",
								pad=5,
								font=("Courier", 14),
								vertical_alignment="top"
							)
						]
				],
				border_width=3,
				relief="sunken",
				pad=5,
				font=("Courier", 14),
				vertical_alignment="top"
			)
		]
    ]
		)
	],
	[
		sg.Column(
			[
				[
					sg.Frame(
						"Description",
						[
								[
									sg.Column(
										[
												[
													sg.Multiline(
														"Prompt", size=(40, 10), key="prompt"
													),
													sg.Multiline(
														"NegativePrompt",
														size=(40, 10),
														key="negative_prompt",
													)
												]
										],
										pad=5,
									),
									sg.Column(
										[
											[
												sg.Frame(
													"Mots-Clefs Émotifs",
													[
															[sg.Combo(mood_keywords_list, key="mood1", size=30)],
															[sg.Combo(mood_keywords_list, key="mood2", size=30)],
															[sg.Combo(mood_keywords_list, key="mood3", size=30)],
													],
													border_width=3,
													relief="sunken",
													pad=5,
													font=("Courier", 14),
													vertical_alignment="top"
												)
											],
											[
												sg.Frame(
												"Mots-Clefs Conceptuels",
												[
														[
															sg.Combo(
																conceptual_keywords_list, key="concept1", size=30
															)
														],
														[
															sg.Combo(
																conceptual_keywords_list, key="concept2", size=30
															)
														],
														[
															sg.Combo(
																conceptual_keywords_list, key="concept3", size=30
															)
														],
												],
												border_width=3,
												relief="sunken",
												pad=5,
												font=("Courier", 14),
												vertical_alignment="top"
											)
										]
									],
									pad=5,
								),
							]
						],
						border_width=3,
						relief="sunken",
						pad=5,
						font=("Courier", 14),
						vertical_alignment="top"
					)
				]
			],
			vertical_alignment="top",
			pad=5,
		)
	],
]

window = sg.Window("StableDiffusion Parameters Generator", layout, font=("Courier", 13),icon=appicon, finalize=True)
while True:
	global xl_model_names
	global sd_model_names
	global xlt_model_names
	global response_xl_models
	global response_sd_models
	global response_xlt_models
	try:
		response_xl_models
	except NameError:
		try:
			response_xl_models = requests.get(url_get_xl_models)
			xl_models = json.loads(response_xl_models.content.decode('utf-8'))
			xl_model_names = [model['model_name'] for model in xl_models]
		except requests.ConnectionError:
			xl_model_names = "Offline"
	try:
		response_sd_models
	except NameError:
		try:
			response_sd_models = requests.get(url_get_sd_models)
			sd_models = json.loads(response_sd_models.content.decode('utf-8'))
			sd_model_names = [model['model_name'] for model in sd_models]
		except requests.ConnectionError:
			sd_model_names = "Offline"
	try:
		response_xlt_models
	except NameError:
		try:
			response_xlt_models = requests.get(url_get_xlt_models)
			xlt_models = json.loads(response_xlt_models.content.decode('utf-8'))
			xlt_model_names = [model['model_name'] for model in xlt_models]
		except requests.ConnectionError:
			xlt_model_names = "Offline"
	event, values = window.read()
	if event == sg.WIN_CLOSED:
		break
	elif event == 'instance':
		if values['instance'] == 'XL':
			selected_models = xl_model_names
			window['checkpoint'].update(values=selected_models)
		elif values['instance'] == 'SD':
			selected_models = sd_model_names
			window['checkpoint'].update(values=selected_models)
		elif values['instance'] == 'XLT':
			selected_models = xlt_model_names
			window['checkpoint'].update(values=selected_models)
	elif event == 'set_model':
		selected_model = values['checkpoint']
		selected_instance = values['instance']
		#CALL PWSH
		# Chemin vers le répertoire contenant le script Python
		py_dir = os.path.dirname(os.path.abspath(__file__))

		# Chemin vers le script PowerShell
		ps_script_set_ckpt = os.path.join(py_dir, '../scripts/Set-Checkpoint.ps1')

		# Exécution du script PowerShell
		subprocess.call(['pwsh.exe', '-File', ps_script_set_ckpt, '-InputCkpt', str(selected_model), '-Instance', str(selected_instance)])
	elif event == 'generate':
		if len(values['template_file']) > 1:
			#CALL PWSH
			# Chemin vers le répertoire contenant le script Python
			py_dir = os.path.dirname(os.path.abspath(__file__))

			# Chemin vers le script PowerShell
			ps_script_fastapi = os.path.join(py_dir, '../scripts/Invoke-SDAPI.ps1')

			# Exécution du script PowerShell
			instance_pwsh_value = values['instance']
			nb_img_pwsh_value = values['nb_img']
			template_pwsh_value = values['template_file']
			subprocess.call(['pwsh.exe', '-File', ps_script_fastapi, '-Instance', str(instance_pwsh_value), '-NbImg', str(nb_img_pwsh_value), '-GenerationTemplate', str(template_pwsh_value)])
		else:
			#CALL PWSH
			# Chemin vers le répertoire contenant le script Python
			py_dir = os.path.dirname(os.path.abspath(__file__))

			# Chemin vers le script PowerShell
			ps_script_pre_data = os.path.join(py_dir, '../scripts/Format-SDData.ps1')

			# Exécution du script PowerShell
			instance_pwsh_value = values['instance']
			nb_img_pwsh_value = values['nb_img']
			checkpoint_pwsh_value = values['checkpoint']
			width_pwsh_value = values['width']
			height_pwsh_value = values['height']
			sampler_pwsh_value = values['sampler']
			seed_pwsh_value = values['seed']
			attention_pwsh_value = values['attention']
			steps_pwsh_value = values['steps']
			restore_face_pwsh_value = values['restore_faces']
			style_pwsh_value = values['style']
			direction_pwsh_value = values['direction']
			prompt_pwsh_value = values['prompt']
			negative_prompt_pwsh_value = values['negative_prompt']
			artist1_pwsh_value = values['artist1']
			artist2_pwsh_value = values['artist2']
			artist3_pwsh_value = values['artist3']
			mood1_pwsh_value = values['mood1']
			mood2_pwsh_value = values['mood2']
			mood3_pwsh_value = values['mood3']
			concept1_pwsh_value = values['concept1']
			concept2_pwsh_value = values['concept2']
			concept3_pwsh_value = values['concept3']
			subprocess.call(['pwsh.exe', '-File', ps_script_pre_data, '-Instance', str(instance_pwsh_value), '-NbImg', str(nb_img_pwsh_value), '-InputCKPT', str(checkpoint_pwsh_value), '-Width', str(width_pwsh_value), '-Height', str(height_pwsh_value), '-Sampler', str(sampler_pwsh_value), '-Seed', str(seed_pwsh_value), '-Attention', str(attention_pwsh_value), '-Steps', str(steps_pwsh_value), '-RestoreFaces', str(restore_face_pwsh_value), '-Style', str(style_pwsh_value), '-Direction', str(direction_pwsh_value), '-Prompt', str(prompt_pwsh_value), '-NegativePrompt', str(negative_prompt_pwsh_value), '-Artist1', str(artist1_pwsh_value), '-Artist2', str(artist2_pwsh_value), '-Artist3', str(artist3_pwsh_value), '-Concept1', str(concept1_pwsh_value), '-Concept2', str(concept2_pwsh_value), '-Concept3', str(concept3_pwsh_value), '-Mood1', str(mood1_pwsh_value), '-Mood2', str(mood2_pwsh_value), '-Mood3', str(mood3_pwsh_value)])