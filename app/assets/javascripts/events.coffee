exports = this
exports.Events = exports.Events || {}

# 页面持续加载
class exports.Events.InfiniteScroll
  @infiniteScroll: ->
    $(document).ready ->
      count     = 2
      totalPage = $('.team-events').data('total-page')
      teamId    = $('.team-events').data('team-id')

      loadArticle = (pageNumber, teamId) ->
        $('a#inifiniteLoader').show 'fast'
        $.ajax
          url: '/teams/' + teamId + '/events?page=' + pageNumber
          type: 'GET'
          datatype: 'html'
          success: (result) ->
            $('a#inifiniteLoader').hide '1000'
            $('.team-events').append result
          false

      $(window).scroll ->
        if $(window).scrollTop() == $(document).height() - $(window).height()
          if count > totalPage
            return false
          else
            loadArticle(count, teamId)

          count++
