##############################################################################################
# Fonction pour forcer la réinitialisation de la conversation
def exec_reset_conversation():
    global conversation
    global conversation_start_datetime

    conversation = []
    conversation_start_datetime = ""

    return str(""),conversation