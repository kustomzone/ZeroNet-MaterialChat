import ZeroFrame from "./ZeroFrame.coffee"
import Message from "./Message.coffee"
import MessageList from "./MessageList.coffee"
import LoginDialog from "./LoginDialog.coffee"
import * as C from './Constant.coffee'
import $ from 'jquery'

class MaterialChatImpl extends ZeroFrame
  init: ->
    @site_info = null
    console.log "MaterialChat initialized."

  onOpenWebsocket: () =>
    C.initialize()
    @cmd "siteInfo", {}, @siteInfoChanged # Intialize siteInfo
    $('#button-send').on 'click', @onSendMessage
    #alert "Ready."
    #new Message "petercxy@zeroid.bit", "Test Message 1"
    #  .render()

  onRequest: (cmd, msg) =>
    switch cmd
      when "setSiteInfo" then @siteInfoChanged msg.params
      else super.onRequest cmd, msg

  siteInfoChanged: (info) =>
    return if !info?
    @site_info = info
    if !@site_info.cert_user_id?
      LoginDialog.tryLogin()
    else
      LoginDialog.dismiss()
      # TODO: Complete login

  onSendMessage: (ev) ->
    ev.preventDefault()
    msgInput = $('#message-input')
    message = msgInput.val().trim()
    msgInput.prop 'disabled', yes
    if message isnt ''
      await MessageList.sendMessage message
    msgInput.val ''
    msgInput.prop 'disabled', no

  getUserData: (required = no) =>
    dataPath = C.PATH_USER_INNER_DATA.replace '{{user}}', @site_info.auth_address
    @cmdp 'fileGet',
      inner_path: dataPath
      required: required

  writeUserData: (obj) =>
    dataPath = C.PATH_USER_INNER_DATA.replace '{{user}}', @site_info.auth_address
    json_raw = unescape(encodeURIComponent(JSON.stringify(obj, undefined, '\t')))
    res = await @cmdp 'fileWrite', [dataPath, btoa(json_raw)]
    if res isnt 'ok'
      await @cmdp 'wrapperNotification', ["error", "File write error #{res.error}"]
    return res

  publishUserContent: =>
    contentPath = C.PATH_USER_INNER_CONTENT.replace '{{user}}', @site_info.auth_address
    await @cmdp 'siteSign', inner_path: contentPath
    await @cmdp 'sitePublish',
      inner_path: contentPath
      sign: no

MaterialChat = new MaterialChatImpl

export default MaterialChat