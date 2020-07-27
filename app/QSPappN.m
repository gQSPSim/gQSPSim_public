function varargout = QSPappN()

    if verLessThan('matlab','9.8') 
      ThisVer = ver('matlab');
      warning('QSPAppN is not supported on %s. Use QSPapp instead.', ThisVer.Release);
    end    

    DefinePaths(false);
    
    % run the units script
    registerUnits
    
    app = QSPViewerNew.Application.ApplicationUI;

    if nargout == 1
        varargout{1} = app;
    end
end
