classdef Summary < handle
    % Summary - A widget for displaying summary information from an nx2
    % cell array
    %----------------------------------------------------------------------
    % This class will be used to describe the structure used to move items
    % back and forth between 2 list boxes as used in gQSPsim
    %----------------------------------------------------------------------
    % Copyright 2020 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   Author: Max Tracy
    %   Revision: 1
    %   Date: 01/15/20
    properties
        Title
        Parent
        Information = cell(0,2)
        HtmlComponent;
    end
    
    properties(Dependent)
        HtmlCode
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and destructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods 
        
        function obj = Summary(varargin)
            %This requires a parent that is a grid layout and information
            %For the box
            if nargin ~= 4
                error("Requires a parent  and information as Input");
            end
            %Call create to instantiate the graphics
            parent =  varargin{1};
            information =  varargin{4};
            row = varargin{2};
            column = varargin{3};
            obj.create(parent,row,column,information);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Creation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Access = private)
        
        function create(obj,parent,row,column,information)
            %Assing Values and create the ui component
            obj.Parent = parent;
            obj.HtmlComponent = uihtml(obj.Parent);
            obj.HtmlComponent.Layout.Row = row;
            obj.HtmlComponent.Layout.Column = column;
            obj.Information = information;
        end
        
        function changeCode(obj)
            %Update the UI to display the current code
            obj.HtmlComponent.HTMLSource = obj.HtmlCode;
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Set/Get
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function set.Information(obj,value)
           %Check input
           validateattributes(value,{'cell'},{'size',[NaN 2]})
           %Set value
           obj.Information = value;
           obj.changeCode();
        end
        
        function htmlcodestring = get.HtmlCode(obj)
            htmlcodestring = cell2htmltext(obj.Information);
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Static
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        
        function htmlString = cell2htmltext(cellArr)
           %Check input
           validateattributes(cellArr,{'cell'},{'size',[NaN 2]})
           [rows,~] = size(cellArr);
           
           %Templates for the output string
           docStart = '<!DOCTYPE html><html><body>';
           docEnd = '</body></html>';
           lineStart = '<p><span style="font-weight:bold"> ';
           lineMiddle = ': </span>';
           lineEnd = '</p>';
           
           %Get lengths for assignment and preallocation
           stalen = length(lineStart);
           midlen = length(lineMiddle);
           endlen = length(lineEnd);
           lineOverHead = stalen + midlen+ endlen;
           
           %Determine how large to preallocate array
           cumulativeLength = length(docStart);
           
           %Length of all the characters from the cell array
           for idx = 1:rows
               %Title Length
               cumulativeLength = cumulativeLength + length(cellArr{idx,1});
               cumulativeLength = cumulativeLength + length(cellArr{idx,2});
           end
           
           %Overhead per line
           cumulativeLength = cumulativeLength + lineOverHead*rows;
           
           %End of the code
           cumulativeLength = cumulativeLength + length(docEnd);
           
           %preallocate
           htmlString = blanks(cumulativeLength);
           idxcount = 1;
           
           htmlString(idxcount:idxcount+length(docStart)) = docStart;
           idxcount = idxcount+length(docStart);
           
           %Iterate through all rows of the cell array
           for idx =1:rows
               %startline html code
               htmlString(idxcount:idxcount+stalen) = lineStart;
               idxcount = idxcount + stalen;
               
               %Bold Text
               htmlString(idxcount:idxcount+ length(cellArr{idx,1})) = cellArr{idx,1};
               idxcount = idxcount + length(cellArr{idx,1});
               
               %Middle html code
               htmlString(idxcount:idxcount+endlen) = lineMiddle;
               idxcount = idxcount + stalen;
               
               %Normal Text
               htmlString(idxcount:idxcount+ length(cellArr{idx,2})) = cellArr{idx,2};
               idxcount = idxcount + length(cellArr{idx,2});
               
               %Endline html code
               htmlString(idxcount:idxcount+endlen) = lineEnd;
               idxcount = idxcount + endlen;
           end  
           
           %Assign the end of the string
           htmlString = horzcat(htmlString,docEnd);
        end
        
    end
    
end

