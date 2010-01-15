function X = listVars(nws, netWorkSpaceName)
% LISTVARS  lists variables in a netWorkSpace, nws.
%
% listVars(nws, netWorkSpaceName) returns a struct array listing
% variables in the named netWorkSpace, with the number of values,
% fetchers, finders and the mode for each. If no netWorkSpaceName
% is given, then current netWorkSpace is used.
%
% If no left hand side, print a tabular listing.
%
% Arguments:
% nws -- netWorkSpace class object.
% netWorkSpaceName -- name of netWorkSpace. It can be different
%   from nws object passed in.

% Copyright 2006-2008 REvolution Computing, Inc.
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%

if nargin == 1
  netWorkSpaceName = nws.currentWs;
end

varList = nwsMex('list vars', socket(server(nws)), netWorkSpaceName);

if nargout == 0
  if length(varList) > 0
    fprintf('Name\tValues\t#Fetch\t#Find\tMode\n');
    fprintf('%s\n', varList);
  else
    fprintf('No variables in %s.\n', netWorkSpaceName);
  end
else
  if length(varList) > 0
    varStructs = struct([]);
    newLine = sprintf('\n');
    tab = sprintf('\t');
    lines = unique([0, strfind(varList, newLine), length(varList)]);
    for x = 2:length(lines)
      l = varList(lines(x-1)+1:lines(x));
      fields_pos = unique([0, strfind(l, tab), length(sprintf(l))]);
      for c = 2:length(fields_pos)
        end_pos = fields_pos(c);
        % exclude tab in the string
        if end_pos ~= length(l)
          end_pos = end_pos - 1;
        end
        fields{c-1} = l(fields_pos(c-1)+1:end_pos);
      end
      varStructs = [varStructs, struct('name', fields{1}, 'values', ...
                    eval(fields{2}), 'fetchers', eval(fields{3}), ...
                    'finders', eval(fields{4}), 'mode', fields{5})];
    end
    X = varStructs;
  else
    X = [];
  end
end
