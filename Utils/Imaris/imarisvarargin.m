function [imaris, varargout] = imarisvarargin(varargin)
%
% [imaris, varargout] = imarisvarargin(varargin)
%
% description:
%    checks if first argument is imaris instance and returns this and rest of input
%    

varargout = {varargin};

if nargin < 1
   imaris = imarisinstance();
   varargout = {{}};
   disp test
elseif isimarisid(varargin{1})
   imaris = imarisinstance(varargin{1});
   varargout = {varargin(2:end)};
   disp doll
else
   imaris = imarisinstance();
end