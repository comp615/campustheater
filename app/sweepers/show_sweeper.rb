class ShowSweeper < ActionController::Caching::Sweeper
  observe Show # This sweeper is going to keep an eye on the Show model
 
  # If our sweeper detects that a show was created call this
  def after_create(show)
    expire_cache_for(show)
  end
 
  # If our sweeper detects that a show was updated call this
  def after_update(show)
    expire_cache_for(show)
  end
 
  # If our sweeper detects that a show was deleted call this
  def after_destroy(show)
    expire_cache_for(show)
  end

  private
  def expire_cache_for(show)
    return unless (show.changed & ['title','writer','location','poster']).length > 0
    expire_fragment(:controller => "shows", 
                :action => "index", 
                :action_suffix => show.semester)
  end
end