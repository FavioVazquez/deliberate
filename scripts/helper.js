// deliberate visual companion -- client-side helper
// Handles selection, event recording, and interactive features

(function() {
  'use strict';

  var SERVER_URL = window.location.origin;
  var selections = {};
  var selectionCount = 0;

  // Selection handling
  window.toggleSelect = function(el) {
    var container = el.closest('.options, .cards');
    var isMultiSelect = container && container.hasAttribute('data-multiselect');
    var choice = el.getAttribute('data-choice');

    if (!isMultiSelect) {
      // Single select: deselect all others in this container
      var siblings = container ? container.querySelectorAll('.option, .card') : [];
      for (var i = 0; i < siblings.length; i++) {
        if (siblings[i] !== el) {
          siblings[i].classList.remove('selected');
          var sibChoice = siblings[i].getAttribute('data-choice');
          if (sibChoice && selections[sibChoice]) {
            delete selections[sibChoice];
            selectionCount--;
          }
        }
      }
    }

    // Toggle this element
    var isSelected = el.classList.toggle('selected');

    if (isSelected) {
      selections[choice] = true;
      selectionCount++;
    } else {
      delete selections[choice];
      selectionCount--;
    }

    // Update selection bar
    updateSelectionBar();

    // Record event
    recordEvent({
      type: 'click',
      choice: choice,
      text: extractText(el),
      selected: isSelected,
      timestamp: Math.floor(Date.now() / 1000)
    });
  };

  function extractText(el) {
    var h3 = el.querySelector('h3');
    var p = el.querySelector('p');
    var parts = [];
    if (h3) parts.push(h3.textContent.trim());
    if (p) parts.push(p.textContent.trim());
    return parts.join(' - ') || el.textContent.trim().substring(0, 100);
  }

  function updateSelectionBar() {
    var bar = document.getElementById('selection-bar');
    var text = document.getElementById('selection-text');
    if (!bar || !text) return;

    if (selectionCount > 0) {
      bar.classList.add('visible');
      text.textContent = selectionCount + ' selected';
    } else {
      bar.classList.remove('visible');
    }
  }

  function recordEvent(event) {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('POST', SERVER_URL + '/events', true);
      xhr.setRequestHeader('Content-Type', 'application/json');
      xhr.send(JSON.stringify(event));
    } catch (e) {
      // Silent fail -- events are supplementary
    }
  }

  // Tooltip system for Canvas visualizations
  var tooltip = document.getElementById('tooltip');

  window.showTooltip = function(x, y, content) {
    if (!tooltip) return;
    tooltip.innerHTML = content;
    tooltip.style.left = (x + 12) + 'px';
    tooltip.style.top = (y + 12) + 'px';
    tooltip.classList.add('visible');
  };

  window.hideTooltip = function() {
    if (!tooltip) return;
    tooltip.classList.remove('visible');
  };

  // Auto-refresh: poll for new content every 2 seconds
  var currentFile = '{{FILENAME}}';
  var refreshInterval = setInterval(function() {
    try {
      var xhr = new XMLHttpRequest();
      xhr.open('GET', SERVER_URL + '/status', true);
      xhr.timeout = 2000;
      xhr.onload = function() {
        if (xhr.status === 200) {
          var data = JSON.parse(xhr.responseText);
          var statusEl = document.getElementById('status-text');
          if (statusEl) statusEl.textContent = 'connected';

          if (data.newest && data.newest !== currentFile) {
            // New content available, reload
            window.location.reload();
          }
        }
      };
      xhr.onerror = function() {
        var statusEl = document.getElementById('status-text');
        if (statusEl) statusEl.textContent = 'disconnected';
      };
      xhr.ontimeout = function() {
        var statusEl = document.getElementById('status-text');
        if (statusEl) statusEl.textContent = 'reconnecting...';
      };
      xhr.send();
    } catch (e) {
      // Silent fail
    }
  }, 2000);

  // Utility: agent color lookup
  window.AGENT_COLORS = {
    'assumption-breaker': '#ff6b6b',
    'first-principles': '#ff9f43',
    'classifier': '#feca57',
    'formal-verifier': '#48dbfb',
    'bias-detector': '#a55eea',
    'systems-thinker': '#0abde3',
    'resilience-anchor': '#c8d6e5',
    'adversarial-strategist': '#ee5a24',
    'emergence-reader': '#686de0',
    'incentive-mapper': '#b33939',
    'pragmatic-builder': '#f6e58d',
    'reframer': '#be2edd',
    'risk-analyst': '#535c68',
    'inverter': '#f9ca24',
    'ml-intuition': '#6ab04c',
    'safety-frontier': '#7ed6df',
    'design-lens': '#dfe6e9'
  };

  window.getAgentColor = function(agentName) {
    return window.AGENT_COLORS[agentName] || '#8b949e';
  };

  // Force-directed graph utilities for idea maps and agent position maps
  window.ForceGraph = function(canvas, options) {
    var ctx = canvas.getContext('2d');
    var nodes = options.nodes || [];
    var edges = options.edges || [];
    var onHover = options.onHover || null;
    var onClick = options.onClick || null;
    var width = canvas.width;
    var height = canvas.height;
    var dpr = window.devicePixelRatio || 1;

    // Set canvas for high DPI
    canvas.width = width * dpr;
    canvas.height = height * dpr;
    canvas.style.width = width + 'px';
    canvas.style.height = height + 'px';
    ctx.scale(dpr, dpr);

    // Initialize positions
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].x === undefined) nodes[i].x = width / 2 + (Math.random() - 0.5) * 200;
      if (nodes[i].y === undefined) nodes[i].y = height / 2 + (Math.random() - 0.5) * 200;
      nodes[i].vx = 0;
      nodes[i].vy = 0;
    }

    function simulate() {
      var k = 0.01; // spring constant
      var repulsion = 5000;
      var damping = 0.85;
      var centerForce = 0.005;

      // Repulsion between all nodes
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          var dx = nodes[j].x - nodes[i].x;
          var dy = nodes[j].y - nodes[i].y;
          var dist = Math.sqrt(dx * dx + dy * dy) || 1;
          var force = repulsion / (dist * dist);
          var fx = (dx / dist) * force;
          var fy = (dy / dist) * force;
          nodes[i].vx -= fx;
          nodes[i].vy -= fy;
          nodes[j].vx += fx;
          nodes[j].vy += fy;
        }
      }

      // Attraction along edges
      for (var e = 0; e < edges.length; e++) {
        var src = edges[e].source;
        var tgt = edges[e].target;
        var dx = tgt.x - src.x;
        var dy = tgt.y - src.y;
        var dist = Math.sqrt(dx * dx + dy * dy) || 1;
        var force = k * (dist - 120);
        var fx = (dx / dist) * force;
        var fy = (dy / dist) * force;
        src.vx += fx;
        src.vy += fy;
        tgt.vx -= fx;
        tgt.vy -= fy;
      }

      // Center gravity
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].vx += (width / 2 - nodes[i].x) * centerForce;
        nodes[i].vy += (height / 2 - nodes[i].y) * centerForce;
        nodes[i].vx *= damping;
        nodes[i].vy *= damping;
        nodes[i].x += nodes[i].vx;
        nodes[i].y += nodes[i].vy;

        // Bounds
        var r = nodes[i].radius || 20;
        nodes[i].x = Math.max(r, Math.min(width - r, nodes[i].x));
        nodes[i].y = Math.max(r, Math.min(height - r, nodes[i].y));
      }
    }

    function draw() {
      ctx.clearRect(0, 0, width, height);

      // Draw edges
      for (var e = 0; e < edges.length; e++) {
        var edge = edges[e];
        ctx.beginPath();
        ctx.moveTo(edge.source.x, edge.source.y);
        ctx.lineTo(edge.target.x, edge.target.y);
        ctx.strokeStyle = edge.color || 'rgba(139,148,158,0.3)';
        ctx.lineWidth = edge.width || 1;
        if (edge.dashed) ctx.setLineDash([6, 4]);
        else ctx.setLineDash([]);
        ctx.stroke();
        ctx.setLineDash([]);
      }

      // Draw nodes
      for (var i = 0; i < nodes.length; i++) {
        var node = nodes[i];
        var r = node.radius || 20;

        ctx.beginPath();
        ctx.arc(node.x, node.y, r, 0, Math.PI * 2);
        ctx.fillStyle = node.color || '#8b949e';
        ctx.globalAlpha = node.opacity || 0.9;
        ctx.fill();
        ctx.globalAlpha = 1;

        if (node.selected) {
          ctx.strokeStyle = '#58a6ff';
          ctx.lineWidth = 3;
          ctx.stroke();
        }

        // Label
        if (node.label) {
          ctx.fillStyle = '#e6edf3';
          ctx.font = (node.fontSize || 11) + 'px -apple-system, system-ui, sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(node.label, node.x, node.y + r + 14);
        }
      }
    }

    // Mouse interaction
    var hoveredNode = null;

    canvas.addEventListener('mousemove', function(e) {
      var rect = canvas.getBoundingClientRect();
      var mx = e.clientX - rect.left;
      var my = e.clientY - rect.top;
      hoveredNode = null;

      for (var i = 0; i < nodes.length; i++) {
        var dx = mx - nodes[i].x;
        var dy = my - nodes[i].y;
        var r = nodes[i].radius || 20;
        if (dx * dx + dy * dy < r * r) {
          hoveredNode = nodes[i];
          canvas.style.cursor = 'pointer';
          if (onHover) onHover(nodes[i], e.clientX, e.clientY);
          return;
        }
      }
      canvas.style.cursor = 'default';
      hideTooltip();
    });

    canvas.addEventListener('click', function(e) {
      if (hoveredNode && onClick) {
        onClick(hoveredNode);
        recordEvent({
          type: 'node-click',
          nodeId: hoveredNode.id,
          nodeLabel: hoveredNode.label,
          timestamp: Math.floor(Date.now() / 1000)
        });
      }
    });

    // Run simulation
    var iterations = 100;
    for (var step = 0; step < iterations; step++) {
      simulate();
    }
    draw();

    return {
      nodes: nodes,
      edges: edges,
      redraw: draw,
      simulate: simulate
    };
  };
})();
