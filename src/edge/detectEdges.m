function [edgeMap, mag, info] = detectEdges(gray, method, params)
% DETECTEDGES  Deteksi tepi 
    if nargin < 3, params = struct(); end
    params = setDefaults(params);

    gray = double(gray);
    if max(gray(:)) > 1, gray = gray / 255; end  

    switch lower(method)

        case 'canny'
            if isempty(params.cannyThresh)
                edgeMap = edge(gray, 'canny', [], params.sigma);
            else
                edgeMap = edge(gray, 'canny', params.cannyThresh, params.sigma);
            end
            mag = double(edgeMap);

        case {'sobel', 'prewitt', 'roberts'}
            smoothed = applyKernel(gray, gaussianKernel(params.sigma));

            switch lower(method)
                case 'sobel'
                    kx = [-1 0 1; -2 0 2; -1 0 1];
                    ky = kx';                    
                case 'prewitt'
                    kx = [-1 0 1; -1 0 1; -1 0 1];
                    ky = kx';
                case 'roberts'
                    kx = [1 0; 0 -1];              
                    ky = [0 1; -1 0];            
            end

            gx = applyKernel(smoothed, kx);
            gy = applyKernel(smoothed, ky);

            mag = sqrt(gx.^2 + gy.^2);
            mag = mag / (max(mag(:)) + eps);    

            th = params.thresh;
            if isempty(th), th = otsuThreshold(mag); end
            edgeMap = mag > th;

        case 'laplace'
            smoothed = applyKernel(gray, gaussianKernel(params.sigma));
            lap = applyKernel(smoothed, [0 1 0; 1 -4 1; 0 1 0]);
            [edgeMap, mag] = zeroCrossing(lap, params.thresh);

        case 'log'
            lg = applyKernel(gray, logKernel(params.sigma));
            [edgeMap, mag] = zeroCrossing(lg, params.thresh);

        otherwise
            error('Metode "%s" tidak dikenal.', method);
    end

    edgeMap = logical(edgeMap);
    info.method = lower(method);
    info.sigma  = params.sigma;
end


% HELPER
function out = applyKernel(g, k)
% Konvolusi dengan padding 'replicate' supaya tidak muncul tepi palsu di batas citra.
    [kh, kw] = size(k);
    if mod(kh, 2) == 1
        gp = padarray(g, [(kh-1)/2, (kw-1)/2], 'replicate', 'both');
    else
        gp = padarray(g, [kh-1, kw-1], 'replicate', 'post');
    end

    out = conv2(gp, rot90(k, 2), 'valid');
end

function k = gaussianKernel(sigma)
    r = ceil(3 * sigma);
    [x, y] = meshgrid(-r:r, -r:r);
    k = exp(-(x.^2 + y.^2) / (2 * sigma^2));
    k = k / sum(k(:));
end

function k = logKernel(sigma)
    r = ceil(3 * sigma);
    [x, y] = meshgrid(-r:r, -r:r);
    q = (x.^2 + y.^2) / (2 * sigma^2);
    k = -(1 / (pi * sigma^4)) * (1 - q) .* exp(-q);
    k = k - mean(k(:));      % jumlah kernel = 0 -> area datar tidak merespons
end

function [edgeMap, mag] = zeroCrossing(L, thFrac)
    [H, W] = size(L);
    S = zeros(H, W); 

    S = pairSlope(S, L, 1:H,   1:W-1, 1:H,   2:W  );
    S = pairSlope(S, L, 1:H-1, 1:W,   2:H,   1:W  );
    S = pairSlope(S, L, 1:H-1, 1:W-1, 2:H,   2:W  );
    S = pairSlope(S, L, 1:H-1, 2:W,   2:H,   1:W-1);

    mag = S / (max(S(:)) + eps);

    th = thFrac;
    if isempty(th)
        cand = mag(mag > 0);                 
        if isempty(cand), th = 0.5; else, th = otsuThreshold(cand); end
    end
    edgeMap = mag > th;
end

function S = pairSlope(S, L, ra, ca, rb, cb)
    A = L(ra, ca);
    B = L(rb, cb);
    d = abs(A - B) .* ((A > 0) ~= (B > 0));
    S(ra, ca) = max(S(ra, ca), d);
    S(rb, cb) = max(S(rb, cb), d);
end

function t = otsuThreshold(v)
    v = v(:);
    v = v(isfinite(v));
    if isempty(v) || max(v) == min(v), t = 0.5; return; end
    counts = histcounts(v, linspace(0, 1, 257));
    p      = counts / sum(counts);
    omega  = cumsum(p);                    
    mu     = cumsum(p .* (1:256));       
    sigmaB = (mu(end) * omega - mu).^2 ./ (omega .* (1 - omega) + eps);
    [~, idx] = max(sigmaB);
    t = idx / 256;
end

function p = setDefaults(p)
    if ~isfield(p, 'sigma'),       p.sigma = 1.5;       end
    if ~isfield(p, 'thresh'),      p.thresh = [];       end
    if ~isfield(p, 'cannyThresh'), p.cannyThresh = [];  end
end
