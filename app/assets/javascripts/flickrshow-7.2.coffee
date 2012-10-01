###
 *  @package  Flickrshow
 *  @subpackage Javascript
 *  @author   Ben Sekulowicz-Barclay
 *  @version  7.2
 *
 *  Flickrshow is a Beseku thing licensed under a Creative Commons Attribution 3.0
 *  Unported License. For more information visit http://www.flickrshow.co.uk.
 ###

flickrshow = (target, settings) ->

  # Ensure that the user has executed the function using the 'new' keyword ...

  if (not this instanceof flickrshow) then return new flickrshow(target, settings)

  # Secure the 'this' variable scope within the function by assigning it
  # to the _ character. We shouldn't need to use 'this' again from here ...

  _ = this

  # Standard event management library, shamelessly lifted from Jon Resich and
  # Peter Paul Koch.
  #
  # http://www.quirksmode.org/blog/archives/2005/10/_and_the_winner_1.html#more
  #
  # @access	private
  # @param 	string
  # @param 	object
  # @return	object

  _.addEvent = (obj, type, fn) ->
    if obj?.addEventListener?
      obj?.addEventListener(type, fn, false)

    else if obj?.attachEvent?
      obj['e' + type + fn] = fn
      obj[type + fn] = () -> obj['e' + type + fn](window.event)

      obj?.attachEvent('on' + type, obj[type + fn])

  # @access	private
  # @return	string

  _.addUrl = () ->
    parameters =
      api_key: '6cb7449543a9595800bc0c365223a4e8'
      extras: 'url_s,url_m,url_z,url_l'
      format: 'json'
      jsoncallback: 'flickrshow_jsonp_' + _.constants.random
      page: _.settings.page
      per_page: _.settings.per_page

    # If the licence/license has been changed from the default ...
    if _.settings.licence? then parameters.license = _.settings.licence
    if _.settings.license? then parameters.license = _.settings.license

    # If we are fetching a gallery's images
    if _.settings.gallery?
      parameters.method = 'flickr.galleries.getPhotos'
      parameters.gallery_id = _.settings.gallery

    # If we are fetching a group's images
    else if _.settings.group?
      parameters.method = 'flickr.groups.pools.getPhotos'
      parameters.group_id = _.settings.group

    # If we are fetching a photoset's images
    else if _.settings.set?
      parameters.method = 'flickr.photosets.getPhotos'
      parameters.photoset_id = _.settings.set

    # If we are fetching images of a person
    else if _.settings.person?
      parameters.method = 'flickr.people.getPhotosOf'
      parameters.user_id = _.settings.person

    # If we are fetching images via a tag search or user search or both
    else if _.settings.tags? or _.settings.user?
      parameters.method = 'flickr.photos.search'

      if _.settings.tags? then parameters.tags = _.settings.tags
      if _.settings.user? then parameters.user_id = _.settings.user

    # If we get this far, we are just displaying recent images ...
    else
      parameters.method = 'flickr.photos.getRecent'

    url = 'http://api.flickr.com/services/rest/?'

    # Loop through the parameters and append them to the URL ...
    for own key, value of parameters
      url += key + '=' + value + '&'

    return url

  # @access	private
  # @param  object
  # @param  string
  # @param  string
  # @param  integer
  # @param  string
  # @return	void

  _.animate = (element, property, endValue, speed, identifier) ->
    # If we already have an animation in this slot, stop it now
    if _.constants.intervals[identifier]? then window.clearInterval(_.constants.intervals[identifier])

    execute = () ->
      currentValue = Math.round(element.style[property].replace(/([a-zA-Z]{2})$/, ''))
      newValue = Math.round(endValue - currentValue)

      # If there is still animation to be had ...
      if (Math.abs(newValue)) > 1
        element.style[property] = Math.floor(currentValue + (newValue / 2)) + 'px'

      # If there is no more animation to be had ...
      else
        element.style[property] = endValue + 'px'
        window.clearInterval(_.constants.intervals[identifier])

    # Define our interval function
    _.constants.intervals[identifier] = window.setInterval(execute, speed/1.5)

    return

  # @access	private
  # @return	void

  _.onClickLeft = () ->
    # If we don't need to animate ...
    if _.constants.isLoading is true
      return

    # Decide which way to go ...
    _.constants.imageCurrent = if _.constants.imageCurrent - 1 < 0 then _.constants.imageTotal - 1 else  _.constants.imageCurrent - 1

    # Animate the element and update the details ...
    _.animate(_.elements.images, 'left', '-' + (_.constants.imageCurrent * _.elements.target.offsetWidth), _.constants.speed, 'i')
    _.showTitle()

    # If there is a user supplied callback for moving, run it now ...
    if typeof _.settings.onMove == 'function' then _.settings.onMove(_.elements.images.childNodes[_.constants.imageCurrent].childNodes[0])

    return

  # @access	private
  # @return	void

  _.onClickPlay = () ->
    if _.constants.isPlaying is false
      _.constants.isPlaying = true
      _.elements.buttons.childNodes[2].style.backgroundImage = 'url(' + _.constants.img_url + 'is.png)'

      execute = () -> _.onClickRight()

      # Create our play interval
      _.constants.intervals['playing'] = window.setInterval(execute, _.settings.interval)

      # If there is a user supplied callback for moving, run it now ...
      if typeof _.settings.onPlay is 'function' then _.settings.onPlay()

    else
      _.constants.isPlaying = false
      _.elements.buttons.childNodes[2].style.backgroundImage = 'url(' + _.constants.img_url + 'ip.png)'

      window.clearInterval(_.constants.intervals['playing'])

      # If there is a user supplied callback for pausing, run it now ...
      if typeof _.settings.onPause is 'function' then _.settings.onPause(_.elements.images.childNodes[_.constants.imageCurrent].childNodes[0])

    return

  # @access	private
  # @return	void

  _.onClickRight = () ->
    # If we don't need to animate ...
    if _.constants.isLoading is true
      return

    # Decide which way to go ...
    _.constants.imageCurrent = if (_.constants.imageCurrent + 2) > _.constants.imageTotal then 0 else _.constants.imageCurrent + 1

    # Animate the element and update the details ...
    _.animate(_.elements.images, 'left', '-' + (_.constants.imageCurrent * _.elements.target.offsetWidth), _.constants.speed, 'i')
    _.showTitle()

    # If there is a user supplied callback for moving, run it now ...window.clearInterval
    if typeof _.settings.onMove is 'function' then _.settings.onMove(_.elements.images.childNodes[_.constants.imageCurrent].childNodes[0])

    return

  # @access	private
  # @param  object
  # @return boolean

  _.onLoadImage = (event) ->
    # Grab the image from the event data ...
    img = (event.srcElement or event.target)

    # Setup our dimension vars ...
    ch = img.offsetHeight
    cw = img.offsetWidth

    # Depending on the ratio of the image, resize it ...
    if cw > ch
      nw = Math.ceil(_.elements.target.offsetWidth + (_.elements.target.offsetHeight / 100))
      nh = Math.ceil((nw/cw) * ch)
    else
      nh = Math.ceil(_.elements.target.offsetHeight + (_.elements.target.offsetHeight / 100))
      nw = Math.ceil((nh/ch) * cw)

    # Update the styles on our image if we can ...
    img.style.height = nh + 'px'
    img.style.left = Math.round((_.elements.target.offsetWidth - nw) / 2) + 'px'
    img.style.position = 'absolute'
    img.style.top = Math.round((_.elements.target.offsetHeight - nh) / 2) + 'px'
    img.style.width = nw + 'px'

    # Update the loading state ...
    _.constants.imageLoaded = _.constants.imageLoaded + 1

    # Calculate the loading state and update the loading bar ...
    percentLoaded = Math.round((_.constants.imageLoaded / _.constants.imageTotal) * 240)
    _.animate(_.elements.loading.childNodes[0], 'width', (if percentLoaded <= 36 then 36 else percentLoaded), 'loading')

    # If we have loaded all of the images ...
    if _.constants.imageLoaded is _.constants.imageTotal
      # Update the current image details ...
      _.showTitle()

      # Remove any loading states/classes
      _.elements.container.removeChild(_.elements.loading)
      _.elements.images.style.visibility = 'visible'
      _.constants.isLoading = false

      # If we are autoplaying, do it now ...
      if _.settings.autoplay is true then _.onClickPlay()

      # If there is a user supplied callback for loading, run it now ...
      if typeof _.settings.onLoad is 'function' then _.settings.onLoad()

    return

  #  @access	private
  #  @param  object
  #  @return boolean

  _.onLoadJson = (event) ->
    # Remove the script call ... and global callback function
    _.elements.script.parentNode.removeChild(_.elements.script)

    # @HACK - If we are fetching photosets, move the variables around a bit ...
    if (event.photoset?)
      for photo, i in event.photoset.photo
        photo.owner = event.photoset.owner

      event.photos = event.photoset

    # If there is an error in the data ...
    if (event.stat? && event.stat is 'fail') or not event.photos
      throw 'Flickrshow: ' + (event.message or 'There was an unknown error with the data returned by Flickr')

    # Define our total images
    _.constants.imageTotal = event.photos.photo.length

    # Add the images/date to the list ...
    for photo, i in event.photos.photo

      # Create our IMG HTML fragment ...
      img = document.createElement('img')
      img.setAttribute('data-flickr-title', photo.title)
      img.setAttribute('data-flickr-photo_id', photo.id)
      img.setAttribute('data-flickr-owner', photo.owner)
      img.setAttribute('rel', i)
      img.style.cursor = 'pointer'
      img.style.display = 'block'
      img.style.margin = '0'
      img.style.padding = '0'

      # Create our test areas ...
      areaT = _.elements.target.offsetHeight * _.elements.target.offsetWidth
      areaZ = photo.height_z * photo.width_z
      areaM = photo.height_m * photo.width_m
      areaS = photo.height_s * photo.width_s

      # Ensure we have all the image URLs ...
      if not photo.url_m then photo.url_m = photo.url_s
      if not photo.url_z then photo.url_z = photo.url_m
      if not photo.url_l then photo.url_l = photo.url_z

      # Update the image source based on the slideshow size ...
      if areaT > areaZ
        img.src = photo.url_l + '?' + _.constants.random
      else if (areaT > areaM)
        img.src = photo.url_z + '?' + _.constants.random
      else if (areaT > areaS)
        img.src = photo.url_m + '?' + _.constants.random
      else
        img.src = photo.url_s + '?' + _.constants.random

      # Create our list node object
      li = document.createElement('li')
      li.style.left = (i * _.elements.target.offsetWidth) + 'px'
      li.style.height = _.elements.target.offsetHeight + 'px'
      li.style.margin = '0'
      li.style.overflow = 'hidden'
      li.style.padding = '0'
      li.style.position = 'absolute'
      li.style.top = '0'
      li.style.width = _.elements.target.offsetWidth + 'px'

      li.appendChild(img)
      _.elements.images.appendChild(li)

      # Create our onLoad event for the image ...
      _.addEvent(img, 'load', _.onLoadImage)

    return

  # @access	private
  # @param  object
  # @return	void

  _.onLoadWindow = (event) ->
    # Grab the target element (a string, (element ID) or a DOM element)
    _.elements.target = if typeof _.elements.target is 'string' then document.getElementById(_.elements.target) else _.elements.target

    # Add in the HTML elements we need
    _.elements.target.innerHTML = '<div class="flickrshow-container" style="background:transparent;height:' + _.elements.target.offsetHeight + 'px;margin:0;overflow:hidden;padding:0;position:relative;width:' + _.elements.target.offsetWidth + 'px"><div class="flickrshow-loading" style="background:transparent url(' + _.constants.img_url + 'bg.png);border-radius:12px;height:24px;left:50%;margin:-12px 0 0 -120px;overflow:hidden;padding:0;position:absolute;top:50%;width:240px;-moz-border-radius:12px;-webkit-border-radius:12px"><div class="flickrshow-loading-bar" style="background:#000;border-radius:12px;height:24px;left:0;margin:0;padding:0;position:absolute;top:0;width:0;-moz-border-radius:12px;-webkit-border-radius:12px"></div></div><ul class="flickrshow-images" style="background:transparent;height:' + _.elements.target.offsetHeight + 'px;left:0;list-style:none;margin:0;padding:0;position:absolute;top:0;visibility:hidden;width:' + _.elements.target.offsetWidth + 'px"></ul><div class="flickrshow-buttons" style="background:transparent url(' + _.constants.img_url + 'bg.png);height:40px;margin:0;padding:0;position:absolute;top:' + _.elements.target.offsetHeight + 'px;width:' + _.elements.target.offsetWidth + 'px"><div class="flickrshow-buttons-left" style="background:#000 url(' + _.constants.img_url + 'il.png) 50% 50% no-repeat;border-radius:12px;cursor:pointer;height:24px;left:auto;margin:0;padding:0;position:absolute;right:40px;top:8px;width:24px;-moz-border-radius:12px;-webkit-border-radius:12px"></div><div class="flickrshow-buttons-right" style="background:#000 url(' + _.constants.img_url + 'ir.png) 50% 50% no-repeat;border-radius:12px;cursor:pointer;height:24px;left:auto;margin:0;padding:0;position:absolute;right:8px;top:8px;width:24px;-moz-border-radius:12px;-webkit-border-radius:12px"></div><div class="flickrshow-buttons-play" style="background:#000 url(' + _.constants.img_url + 'ip.png) 50% 50% no-repeat;border-radius:12px;cursor:pointer;height:24px;left:8px;margin:0;padding:0;position:absolute;right:auto;top:8px;width:24px;-moz-border-radius:12px;-webkit-border-radius:12px;"></div><p class="flickrshow-buttons-title" style="background:#000;border-radius:12px;color:#FFF;cursor:pointer;font:normal normal 600 11px/24px helvetica,arial,sans-serif;height:24px;left:40px;margin:0;overflow:hidden;padding:0;position:absolute;right:auto;text-align:center;text-shadow:none;text-transform:capitalize;top:8px;width:' + (_.elements.target.offsetWidth - 112) + 'px;-moz-border-radius:12px;-webkit-border-radius:12px">&nbsp</p></div></div>'

    # Get the elements we need from the above as DOM objects
    _.elements.container = _.elements.target.childNodes[0]

    _.elements.buttons = _.elements.target.childNodes[0].childNodes[2]
    _.elements.images = _.elements.target.childNodes[0].childNodes[1]
    _.elements.loading = _.elements.target.childNodes[0].childNodes[0]

    # If we are displaying the buttons bar, we need to add the events too
    if (false is _.settings.hide_buttons)
      _.addEvent(_.elements.images, 'click', _.toggleButtons)
      _.addEvent(_.elements.container, 'mouseover', _.showButtons)
      _.addEvent(_.elements.container, 'mouseout', _.hideButtons)

      _.addEvent(_.elements.buttons.childNodes[0], 'click', _.onClickLeft)
      _.addEvent(_.elements.buttons.childNodes[1], 'click', _.onClickRight)
      _.addEvent(_.elements.buttons.childNodes[2], 'click', _.onClickPlay)

      _.addEvent(_.elements.buttons.childNodes[3], 'click', _.showFlickr)

    # Generate a random callback function ...
    window['flickrshow_jsonp_' + _.constants.random] = _.onLoadJson

    # ... And then add our script to load form Flickr ...
    _.elements.script = document.createElement('script')
    _.elements.script.async = true
    _.elements.script.src = _.addUrl('flickrshow_jsonp_' + _.constants.random)

    (document.getElementsByTagName('head')[0] or document.getElementsByTagName('body')[0]).appendChild(_.elements.script)

    return

  # @access	private
  # @return	void

  _.hideButtons = () ->
    if (_.constants.isLoading is true) or (_.constants.isButtonsOpen is false) then return

    _.constants.isButtonsOpen = false
    _.animate(_.elements.buttons, 'top', _.elements.target.offsetHeight, _.constants.speed, 'buttons')

    return

  # @access	private
  # @return	void

  _.showButtons = () ->
    if (_.constants.isLoading is true) or (_.constants.isButtonsOpen is true) then return

    _.constants.isButtonsOpen = true
    _.animate(_.elements.buttons, 'top', _.elements.target.offsetHeight - 40, _.constants.speed, 'buttons')

    return

  # @access	private
  # @return	void

  _.toggleButtons = () ->
    if _.constants.isButtonsOpen is true then _.hideButtons() else _.showButtons()

    return

  # @access	private
  # @return	void

  _.showFlickr = () ->
    img = _.elements.images.childNodes[_.constants.imageCurrent].childNodes[0]

    # If we can't get an image, stop here ...
    if not img? then return

    # Redirect to the image's Flickr page ...
    window.location = 'http://www.flickr.com/photos/' + img.getAttribute('data-flickr-owner') + '/' + img.getAttribute('data-flickr-photo_id') + '/'

    return

  # @access	private
  # @return	void

  _.showTitle = () ->
    img = _.elements.images.childNodes[_.constants.imageCurrent].childNodes[0]

    # If we can't get an image, stop here ...
    if not img? then return

    # Update the details
    _.elements.buttons.childNodes[3].innerHTML = (_.constants.imageCurrent + 1) + '/' + _.constants.imageTotal + ' - ' + img.getAttribute('data-flickr-title')

    return

  # The objects containing our constants and settings, and the objects which
  # will later directly reference DOM elements

  _.constants =
    img_url: 'http://www.flickrshow.co.uk/static/images/'
    intervals:[]
    imageCurrent:0
    imageLoaded:0
    imageTotal:0
    isButtonsOpen:false
    isLoading:true
    isPlaying:false
    random: Math.floor(Math.random() * 999999999999)
    speed: 100

  _.elements =
    buttons: null
    button1: null
    button2: null
    button3: null
    button4: null
    container: null
    images: null
    loading: null
    script: null
    target: null

  _.settings =
    autoplay: false
    gallery: null
    group: null
    hide_buttons: false
    interval: 3000
    license: '1,2,3,4,5,6,7'
    onLoad: null
    onMove: null
    onPlay: null
    onPause: null
    page: '1'
    person: null
    per_page: '50'
    set: null
    tags: null
    user: null

  # The user should have specified an element by ID or as a DOM object. Assign either
  # to the instance variable. If it is an ID only, we shall fetch it later.

  _.elements.target = target

  # Loop through our predefined allowed settings, above, and check through the
  # user supplied list, overriding in any that have been provided by the user

  for own key,value of settings
    _.settings[key] = value

  # For backwards compatibility with Flickrshow 6.X, we should also test
  # for the presence of the variables under their deprecated names and assign them
  # in the same way.

  if settings.flickr_group? then _.settings.group = settings.flickr_group
  if settings.flickr_photoset? then _.settings.set = settings.flickr_photoset
  if settings.flickr_tags? then _.settings.tags = settings.flickr_tags
  if settings.flickr_user? then _.settings.user = settings.flickr_user

  # Once we get to this point all that is left is to wait until the DOM is ready
  # to be manipulated, so we can start building our slideshow in the target element.

  _.addEvent(window, 'load', _.onLoadWindow)

  constants: _.constants
  elements: _.elements
  settings: _.settings
  left: _.onClickLeft
  right: _.onClickRight
  play: _.onClickPlay

# As a bonus for jQuery users, we bind the flickrshow plugin to $.fn whcih
# allows the function to be executed on a jQuery element...

if window.jQuery?
  window.jQuery.fn.flickrshow = (settings) ->
    new flickrshow(window.jQuery(this)[0], settings)