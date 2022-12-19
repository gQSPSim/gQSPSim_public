classdef hGSAObject < QSP.GlobalSensitivityAnalysis

    methods (Static)

        function value = getPropertyValueHelper(gsaResults, propertyName)
            % Helper method to access protected properties on
            % QSP.GlobalSensitivityAnalysis objects.
            value = gsaResults.(propertyName);
        end

        function varargout = executeMethodHelper(gsaResults, methodName, varargin)
            % Helper method to access protected methods on
            % QSP.GlobalSensitivityAnalysis objects.
            varargout = cell(1, nargout);
            [varargout{:}] = gsaResults.(methodName)(varargin{:});
        end
    end

end