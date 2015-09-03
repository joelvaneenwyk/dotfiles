import html2text
import weechat

def modifier_cb(data, modifier, modifier_data, string):
    try:
        return html2text.html2text(string).replace("\n", " ")
    except Exception:
        return string

weechat.register("strip_html", "Jonathan Van Eenwyk", "1.0", "BSD", "Strip HTML from messages", "", "")
weechat.hook_modifier("irc_in_privmsg", "modifier_cb", "")

