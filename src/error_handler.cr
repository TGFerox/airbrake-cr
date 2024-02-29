class Airbrake::ErrorHandler < HTTP::ErrorHandler
  def call(context)
     begin
       call_next(context)
     rescue ex : Exception
       # Report the exception to Airbrake
       Airbrake.notify(ex)
       call_next(context)
       # Handle the exception (e.g., log it, return a 500 response)
     end
  end
 end