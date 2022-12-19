function varargout = unpack(data)

for k=1:length(data)
    varargout{k} = data{k};
end

end
