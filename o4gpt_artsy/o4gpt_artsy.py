import os
import subprocess
import gradio as gr
import openai
from langchain.chat_models import AzureChatOpenAI
from langchain.schema import AIMessage, HumanMessage, SystemMessage

from utils.exec_reset_conversation import exec_reset_conversation

global conversation
conversation = []

sys_prompt = "I want you to act as a prompt generator for Stable Diffusion. You must use weights to put emphasis on words or groups of words. The syntax for using weights is the following:\n Weights Syntax Example```(Ultra detailed:1.45),(photo:1.2) of a (very colorful:1.1) (mesmerizing ultra starry sky:1.4), (Psychedelic Art:1.3),(Digital Art:1.4)```. The number at the end of each parenthesis enclosed block of text can be a value anywhere between 1.1-1.5. I will now provide you with a subject and style that I want you to use for creating a prompt and I want you to write the prompt using the weight format I just explained."

o4gpt_message_box = gr.Textbox(label="Votre message",show_label=False,lines=5,placeholder="Inscrire votre message/question\nNote: Prend en charge le format Markdown.",container=True,show_copy_button=True, autofocus=True, autoscroll=True,interactive=True)
submit_message_button = gr.Button(value="✏️ Envoyer votre message",variant="primary",size="lg")
reset_conversation_button = gr.ClearButton(value="🧽 Réinitialiser",variant="secondary",size="lg")

theme="fxmikau/o4gpt"

py_dir = os.path.dirname(os.path.abspath(__file__))
ps_script = os.path.join(py_dir, 'utils/get_userpic.ps1')
subprocess.call(['powershell.exe', '-File', ps_script])
o4gpt_chatbot = gr.Chatbot(label="Conversation",show_label=True,show_copy_button=True,height=500,avatar_images=['user_pic.jpg',"o4gpt_artsy.png"])

def invoke_o4gpt_artsy(user_prompt,conversation):
    langchain_format_conversation = []
    if len(conversation) == 0:
        langchain_format_conversation.append(SystemMessage(content=sys_prompt))
    for human, ai in conversation:
        langchain_format_conversation.append(HumanMessage(content=human))
        langchain_format_conversation.append(AIMessage(content=ai))
    langchain_format_conversation.append(HumanMessage(content=user_prompt))

    openai.api_type = "azure"
    openai.api_version = "2023-03-15-preview"
    openai.api_base = os.getenv("OPENAI_API_BASE")
    openai.api_key = os.getenv("OPENAI_API_KEY")
    max_response_tokens=2000
    o4gpt_artsy = AzureChatOpenAI(
        openai_api_base=openai.api_base,
        openai_api_version=openai.api_version,
        deployment_name = "O4-GPT",
        tiktoken_model_name="gpt-3.5-turbo-0301",
        openai_api_key=openai.api_key,
        openai_api_type=openai.api_type,
        max_tokens=max_response_tokens,
        temperature=0.9,
        frequency_penalty = 0.1,
        presence_penalty = 0.08,
    )
    gpt_response = o4gpt_artsy(langchain_format_conversation)

    clean_response = gpt_response.content
    conversation.append((user_prompt,clean_response))
    return str(""),conversation

with gr.Blocks(theme=theme,title="O4GPT-SD") as o4gpt_artsy_gui:
    with gr.Row():
        with gr.Column(scale=1):
            gr.Markdown(value="""
                    [<img src="https://raw.githubusercontent.com/fxbeaulieu/New-ImageGeneration/main/v2/New-ImageGeneration/New-ImageGeneration.png" width="120px"/>](https://raw.githubusercontent.com/fxbeaulieu/New-ImageGeneration/main/v2/New-ImageGeneration/New-ImageGeneration.png)


                    # O4GPT Édition Artsy
                    """)
    with gr.Row():
        with gr.Group():
            with gr.Row():
                o4gpt_chatbot.render()
            with gr.Row():
                o4gpt_message_box.render()
            with gr.Row(variant="panel"):
                with gr.Column(scale=2):
                    reset_conversation_button.render()
                with gr.Column(scale=6):
                    submit_message_button.render()

    reset_conversation_button.click(fn=exec_reset_conversation,inputs=[],outputs=[o4gpt_message_box,o4gpt_chatbot])
    submit_message_button.click(fn=invoke_o4gpt_artsy,inputs=[o4gpt_message_box,o4gpt_chatbot],outputs=[o4gpt_message_box,o4gpt_chatbot])

o4gpt_artsy_gui.launch(
    favicon_path="o4gpt_artsy.png",
    server_port=64641
)